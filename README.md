
![URLMockSession](https://raw.githubusercontent.com/AlbertoLourenco/URLMockSession/master/github-assets/cover.png)

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat)](http://badges.mit-license.org)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2FAlbertoLourenco%2FURLMockSession.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2FAlbertoLourenco%2FURLMockSession?ref=badge_shield)

A simple class that makes REST API requests and mock these datas automatically (if you wanna).

If you don't want to use larger libraries than will takes up large spaces on your project, add this class and make all of your REST API requests and mock these datas when you need this.

> When you are implementing tests, your project cannot makes REST API requests. And with URLMockSession you can load local mocked datas without hard work.

Why use this class?

* Shortly code;
* Simple application;
* Works with threads;
* Mock your API responses;
* Easily switch to load mock or REST API data;
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

After complete class configs, make your REST API request:

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

If you want to see all mocked data, implement this script:

```swift
let mocks = MockManager.shared.all() // Array<Mock>
for item in mocks {
    print(item.endpoint)
}
```

> I used this class in my iOS projects and now I'm publishing it to share it with other developers and get answers about it. If you have any ideas to add, please make a `pull request`. <br /><br />
> Feel free to use, copy and change what you need.

