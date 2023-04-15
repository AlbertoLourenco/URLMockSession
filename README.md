
![URLMockSession](https://raw.githubusercontent.com/AlbertoLourenco/URLMockSession/master/github-assets/cover.png)

A simple class that makes REST API requests and mock these datas automatically (if you wanna).

If you don't want to use larger libraries than will takes up large spaces on your project, add this class and make all of your REST API requests and mock these datas when you need this.

> With URLMockSession you can load local mocked datas without hard work.

Why use this class?

- [x] Shortly code;
- [x] Simple application;
- [x] Works with threads;
- [x] Mock your API responses;
- [x] Easily switch to load mock or REST API data;
- [x] This class takes up less space (only 14kb);

# How to use

First set all of your `configs` to apply URLMockSession basic informations:

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

## Requesting REST API

After complete class configs, make your REST API request:

```swift
let manager = URLMockSession(with: config)
manager.request(method: .get,
                endpoint: "01001000/json/",
                parameters: [:],
                authenticated: false,
                responseType: Dictionary<String, String>.self) { (response, code) in
                    print(String(describing: response))
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

## Requirements

```
- iOS 10+
- Swift 5
- Xcode 10
```

## This project uses:

```
- UIKit
- Decodable
- URLSession
- FileManager
- UserDefaults
```

## Using extensions:

```
- Date
- Dictionary
- URLResponse
```

