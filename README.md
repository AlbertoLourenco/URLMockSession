# URLMockSession

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat)](http://badges.mit-license.org)

A simple class that makes REST API requests and mock these datas automatically (if you wanna).

If you don't wants to use bigger libraries that will takes up large spaces on your project, add this class and make all of your REST API requests and mock these datas when you need this.

When you are implementing tests your project cannot makes REST API requests. And with URLMockSession you can load local mocked datas with no more hard works.

Why use this class?

* Shortly code;
* Simple application;
* Works with threads;
* Mock your API responses;
* Easily switch to load mock ou REST API data;
* This class takes up less space (only 14kb);

This class uses:

* [Decodable](https://developer.apple.com/documentation/swift/decodable)
* [URLSession](https://developer.apple.com/documentation/foundation/urlsession)
* [FileManager](https://developer.apple.com/documentation/foundation/filemanager)
* [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)

And apply some extensions to:

* [Dictionary](https://developer.apple.com/documentation/swift/dictionary)
* [URLResponse](https://developer.apple.com/documentation/foundation/urlresponse)
* [Date](https://developer.apple.com/documentation/foundation/date)

## Applying Configs

First set all of your "configs" to apply URLMockSession basic informations:

```swift
var config = MockConfig()
        
config.baseURL = "https://viacep.com.br/ws/"
config.timeout = 60
config.headers = []
config.token = ""
config.mock = true
config.testingFail = false
config.testingSuccess = false
```

You can see more details about each attrs inside `URLMockSession.swift` class.

## Requesting REST API

After setting class configs, do your REST API request:

```swift
let manager = URLMockSession(with: config)
manager.request(method: .get,
                endpoint: "01001000/json/",
                parameters: [:],
                authenticated: false,
                responseType: Dictionary<String, String>.self) { (response, code) in
                    self.lblResult?.text = String(describing: response)
                }
```

## Getting all mocked data

If you wants to see all mocked data, implement this script:

```swift
let mocks = MockManager.shared.all() // Array<Mock>
for item in mocks {
    print(item.endpoint)
}
```

> I've used this class on my iOS projects and now I'm publishing it to share it with another developers and receive responses about that. If you have some idea to add, please make a pull request.

> Feel free to use, copy and change what you wants.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

