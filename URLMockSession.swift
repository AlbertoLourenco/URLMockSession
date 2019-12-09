//
//  APIRequest.swift
//  URLSession
//
//  Created by Alberto Lourenço on 12/1/19.
//  Copyright © 2019 Alberto Lourenço. All rights reserved.
//

import Foundation

//-----------------------------------------------------------------------
//  MARK: - Enum
//-----------------------------------------------------------------------

enum MockRequestType {
    case get
    case post
    case put
    case patch
    case delete
    case formEncoded
}

//-----------------------------------------------------------------------
//  MARK: - Structs
//-----------------------------------------------------------------------
/*
 *...................
 * >> MockConfig
 *-------------------
 * baseURL: API base URL
 * timeout: request timeout
 * token: API OAuth token
 * mock: enable mock
 * testingFail: load mock with error
 * testingSuccess: load mock with success
 * headers: adding more header fields
 *
 * >>>> Testing attrs needs to be false to load REST API data
 */
struct MockConfig {
    var baseURL: String = ""
    var timeout: TimeInterval = 10
    var token: String = ""
    var mock: Bool = true
    var testingFail: Bool = false
    var testingSuccess: Bool = false
    var headers: Array<Dictionary<String, String>> = []
}
/*
 *...................
 * >> Mock
 *-------------------
 * date: mock last updated date
 * path: `documents` local file path
 * fileName: mock file name
 * endpoint: endpoint requested
 * responseCode: endpoint response code
 * appVersion: app version at last mocked data
 * content: mock json content string
 */
struct Mock {
    var date: String = ""
    var path: String = ""
    var fileName: String = ""
    var endpoint: String = ""
    var responseCode: Int = 0
    var appVersion: String = ""
    var content: String = ""
    init(with dictionary: Dictionary<String, Any>) {
        self.date = dictionary["date"] as? String ?? ""
        self.path = dictionary["path"] as? String ?? ""
        self.fileName = dictionary["fileName"] as? String ?? ""
        self.endpoint = dictionary["endpoint"] as? String ?? ""
        self.responseCode = dictionary["responseCode"] as? Int ?? 0
        self.appVersion = dictionary["appVersion"] as? String ?? ""
    }
}

//-----------------------------------------------------------------------
//  MARK: - URLMockSession
//-----------------------------------------------------------------------

class URLMockSession {
    
    var config = MockConfig()
    
    init(with config: MockConfig) {
        self.config = config
    }
    
    func request<T:Decodable>(method: MockRequestType,
                              endpoint: String,
                              parameters: Dictionary<String, Any>,
                              authenticated: Bool = false,
                              responseType: T.Type,
                              completion: @escaping (_ response: Any?, _ code: Int) -> Void) {
        var serverURL: String = config.baseURL + endpoint
        let request = NSMutableURLRequest()
        request.timeoutInterval = config.timeout
        request.cachePolicy = .useProtocolCachePolicy
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // addin headers
        for header in config.headers {
            for key in header.keys {
                request.setValue(header[key], forHTTPHeaderField: key)
            }
        }
        let session = URLSession.shared
        switch method {
            case .get:
                serverURL += parameters.buildQueryString()
                request.httpMethod = "GET"
                break
            case .patch:
                serverURL += parameters.buildQueryString()
                request.httpMethod = "PATCH"
                break
            case .put:
                request.httpMethod = "PUT"
                request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                break
            case .post:
                request.httpMethod = "POST"
                request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                break
            case .delete:
                request.httpMethod = "DELETE"
                request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                break
            case .formEncoded:
                request.httpMethod = "POST"
                request.httpBody = parameters.buildQueryString(encoded: true).data(using: String.Encoding.utf8)!
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                break
        }
        if !config.token.isEmpty && authenticated {
            request.setValue("Bearer " + config.token, forHTTPHeaderField: "Authorization")
        }
        request.url = URL(string: serverURL)
        print("--------------------------------------------------------")
        print("Parameters: \(parameters)")
        print("Request URL: \(request.url!.absoluteString)")
        print("--------------------------------------------------------")
        //---------------------------------------------------------
        //  Running tests
        //---------------------------------------------------------
        if config.testingSuccess || config.testingFail {
            if config.testingFail {
                DispatchQueue.main.async { completion(nil, 400) }
                return
            }
            if config.testingSuccess {
                if let mock = MockManager.shared.load(endpoint) {
                    if T.self == String.self, let responseString = String(data: mock, encoding: .utf8) {
                        DispatchQueue.main.async { completion(responseString, 200) }
                    }else{
                        let parse = try? JSONDecoder().decode(T.self, from: mock)
                        DispatchQueue.main.async { completion(parse, 200) }
                    }
                }else{
                    DispatchQueue.main.async { completion(nil, 200) }
                }
            }
            return
        }
        //---------------------------------------------------------
        //  Load API
        //---------------------------------------------------------
        let task = session.dataTask(with: request as URLRequest,
                                    completionHandler: {data, response, error -> Void in
            let responseCode = response?.getStatusCode() ?? 0
            guard error == nil else {
                DispatchQueue.main.async { completion(nil, responseCode) }
                return
            }
            if let responseData = data, responseData.count != 0 {
                if self.config.mock {
                    if let responseString = String(data: responseData, encoding: .utf8) {
                        print("Response: \(responseString)")
                        MockManager.shared.mock(endpoint: endpoint, json: responseString, code: responseCode)
                    }
                }
                do {
                    let parse = try JSONDecoder().decode(T.self, from: responseData)
                    DispatchQueue.main.async { completion(parse, responseCode) }
                }catch{
                    print("-> Entity: " + String(describing: T.self))
                    print("-> Error: " + String(describing: error))
                }
            }else{
                DispatchQueue.main.async { completion(nil, responseCode) }
            }
        })
        task.resume()
    }
}

//-----------------------------------------------------------------------
//  MARK: - MockManager
//-----------------------------------------------------------------------

class MockManager {
    
    static let shared = MockManager()
    
    func all() -> Array<Mock> {
        var array: Array<Mock> = []
        if let list = UserDefaults.standard.dictionary(forKey: "Mocks") {
            for key in list.keys {
                if let item = list[key] as? Dictionary<String, Any> {
                    var mock = Mock(with: item)
                    if let data = self.load(mock.endpoint) {
                        mock.content = String(decoding: data, as: UTF8.self)
                    }
                    array.append(mock)
                }
            }
        }
        return array
    }
    
    func load(_ endpoint: String) -> Data? {
        let fileManager = FileManager.default
        let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = endpoint.replacingOccurrences(of: "/", with: "_")
        let folderURL = documentPath.appendingPathComponent("Mocks", isDirectory: true)
        let filePath = folderURL.appendingPathComponent("\(fileName).json").absoluteString.replacingOccurrences(of: "file://", with: "")
        if fileManager.fileExists(atPath: filePath) {
            return FileManager.default.contents(atPath: filePath)
        }
        return nil
    }
    
    func mock(endpoint: String, json: String, code: Int) {
        guard let path = self.mockFolderPath() else {
            return
        }
        let fileName = endpoint.replacingOccurrences(of: "/", with: "_")
        let fileURL = path.appendingPathComponent("\(fileName).json")
        print("--------------------------------------------------------")
        print("Mock path: \(fileURL.absoluteString)")
        print("--------------------------------------------------------")
        if FileManager.default.fileExists(atPath: fileURL.absoluteString) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        do {
            if let data = json.data(using: .utf8) {
                let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                let data = try JSONSerialization.data(withJSONObject: object, options: [])
                try data.write(to: fileURL, options: [])
                self.store(fileName: fileName, path: fileURL.absoluteString, endpoint: endpoint, code: code)
            }
        }catch{
            print(error)
        }
    }
    
    private func store(fileName: String, path: String, endpoint: String, code: Int) {
        var mocks: Dictionary<String, Any> = UserDefaults.standard.dictionary(forKey: "Mocks") ?? [:]
        mocks[fileName] = ["date" : Date().toString(),
                           "path" : path,
                           "fileName" : fileName,
                           "endpoint" : endpoint,
                           "responseCode" : code,
                           "appVersion" : self.getAppVersion()]
        UserDefaults.standard.set(mocks, forKey: "Mocks")
    }
    
    private func mockFolderPath() -> URL? {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentPath.appendingPathComponent("Mocks", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folderURL.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: folderURL.path,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
                return folderURL
            }catch{
                print(error.localizedDescription)
                return nil
            }
        }else{
            return folderURL
        }
    }
    
    private func getAppVersion() -> String {
        if let info = Bundle.main.infoDictionary,
            let version = info["CFBundleShortVersionString"] as? String,
            let build = info["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return ""
    }
}

//-----------------------------------------------------------------------
//  MARK: - Extensions
//-----------------------------------------------------------------------

extension Dictionary {
    func buildQueryString(encoded: Bool = false) -> String {
        var urlVars:[String] = []
        for (key, value) in self {
            if value is Array<Any> {
                for v in value as! Array<Any> {
                    if let encodedValue = "\(v)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                        urlVars.append((key as! String) + "[]=" + encodedValue)
                    }
                }
            }else{
                if let val = value as? String {
                    if let encodedValue = val.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                        urlVars.append((key as! String) + "=" + encodedValue)
                    }
                }else{
                    urlVars.append((key as! String) + "=\(value)")
                }
            }
        }
        return urlVars.isEmpty ? "" : (encoded ? "?" : "") + urlVars.joined(separator: "&")
    }
}

extension URLResponse {
    func getStatusCode() -> Int? {
        if let httpResponse = self as? HTTPURLResponse {
            return httpResponse.statusCode
        }
        return nil
    }
}

extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
