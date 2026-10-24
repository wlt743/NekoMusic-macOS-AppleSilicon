import Foundation

/// 直接从远程 MP3 的 ID3 头读取封面与歌词：
/// 只发一次 Range 请求取前 N KB，不下载整首歌。
enum ID3MetadataReader {
    struct Result {
        var cover: Data?
        var lyrics: String?
        var title: String?
        var artist: String?
        var album: String?
    }

    private static var cache: [String: Result] = [:]
    private static let lock = NSLock()

    static func cached(for urlString: String) -> Result? {
        lock.lock(); defer { lock.unlock() }
        return cache[urlString]
    }

    static func load(urlString: String, maxBytes: Int = 256 * 1024) async -> Result? {
        if let hit = cached(for: urlString) { return hit }
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("bytes=0-\(maxBytes - 1)", forHTTPHeaderField: "Range")
        request.timeoutInterval = 15

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let result = parse(data) else { return nil }
            lock.lock(); cache[urlString] = result; lock.unlock()
            return result
        } catch {
            return nil
        }
    }

    // MARK: - 解析

    static func parse(_ data: Data) -> Result? {
        guard data.count > 10,
              data[0] == 0x49, data[1] == 0x44, data[2] == 0x33 else { return nil }

        let tagSize = (Int(data[6]) << 21) | (Int(data[7]) << 14) | (Int(data[8]) << 7) | Int(data[9])
        let bodyEnd = min(10 + tagSize, data.count)
        guard bodyEnd > 10 else { return nil }
        let body = data.subdata(in: 10..<bodyEnd)

        var result = Result()
        var pos = 0
        while pos + 10 <= body.count {
            let idBytes = body.subdata(in: pos..<pos+4)
            if idBytes[0] == 0 { break }
            let fid = String(data: idBytes, encoding: .ascii) ?? ""
            guard fid.count == 4 else { break }
            let frameSize = (Int(body[pos+4]) << 24) | (Int(body[pos+5]) << 16)
                | (Int(body[pos+6]) << 8) | Int(body[pos+7])
            guard frameSize > 0, pos + 10 + frameSize <= body.count else { break }
            let content = body.subdata(in: pos+10..<pos+10+frameSize)

            switch fid {
            case "APIC":
                result.cover = parseAPIC(content)
            case "USLT":
                result.lyrics = parseTextFrame(content, skipLanguage: true)
            case "TIT2":
                result.title = parseTextFrame(content)
            case "TPE1":
                result.artist = parseTextFrame(content)
            case "TALB":
                result.album = parseTextFrame(content)
            default:
                break
            }
            pos += 10 + frameSize
        }
        return result
    }

    private static func parseTextFrame(_ content: Data, skipLanguage: Bool = false) -> String? {
        guard !content.isEmpty else { return nil }
        let encoding = content[0]
        var start = 1
        if skipLanguage { start += 3 }   // USLT: encoding + language(3) + descriptor
        guard content.count > start else { return nil }

        var bytes = content.subdata(in: start..<content.count)
        // descriptor 以 \0 结尾
        if let zero = bytes.firstIndex(of: 0) { bytes = bytes.subdata(in: 0..<zero) }

        switch encoding {
        case 0: return String(data: bytes, encoding: .isoLatin1)
        case 1: return String(data: bytes, encoding: .utf16)
        case 2: return String(data: bytes, encoding: .utf16BigEndian)
        case 3: return String(data: bytes, encoding: .utf8)
        default: return String(data: bytes, encoding: .utf8)
        }
    }

    private static func parseAPIC(_ content: Data) -> Data? {
        guard content.count > 4 else { return nil }
        var idx = 1
        while idx < content.count && content[idx] != 0 { idx += 1 }   // mime
        idx += 1
        guard idx < content.count else { return nil }
        idx += 1                                                     // picture type
        while idx < content.count && content[idx] != 0 { idx += 1 }   // description
        idx += 1
        guard idx < content.count else { return nil }
        return content.subdata(in: idx..<content.count)
    }
}
