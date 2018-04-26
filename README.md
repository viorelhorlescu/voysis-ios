Voysis iOS Swift SDK
=====================


This document provides a brief overview of the Voysis iOS SDK.
This is an iOS library that facilitates sending voice
queries to a Voysis instance. The SDK streams audio from the device microphone 
to the Voysis backend servers when called by the client application.


Documentation
-------------


The full documentation for this library can be found here: [Voysis Developer Documentation](https://developers.voysis.com/docs)


Requirements
-------------


- iOS 8.0+
- Xcode 9.0+
- Swift 4.0+


Overview
-------------


The `Voysis.Service` class is the main interface used to process voice recognition requests.
It is accessed via the static `Voysis.ServiceProvider.make(config: Config(url : "http://ADD-URL.com/websocket"))` method.
The sdk communicates to the network using a websocket connection accomplished using the `Starscream.framework`.
The iOS core library, `Audio Toolbox Audio Queue Services` is used for recording the users voice.


Context - Entities
-------------


One of the features of using the Voysis service is that different json response types can be returned depending on what service you're subscribed to.
The json objects which vary in type are Context and Entities. see [Api Docs](https://developers.voysis.com/docs/apis-1#section-stream-audio-data) for information.
In order to facilitate this in the sdk and avail of the swift 4.0 `Codable` serialization protocol, the object structure for Context and Entities must be declared in advance and included during service creation. See the [demo application](https://github.com/voysis/voysis-ios/tree/master/example/VoysisDemo/VoysisDemo) and Usage below for an example of this in action.


Usage
-------------


- The first step is to create a Voysis.Servie instance (Make sure to be using a valid url, Context and Entities types)

    ```let voysis = Voysis.ServiceProvider<CommerceContext, CommerceEntities>.Make(config: Config(url: URL(string: "//INCLUDE-URL-HERE")!))```


- Next, to make a request you can do the following.

     ```try? voysis.startAudioQuery(context: self.context, eventHandler: self.onVoysisEvent, errorHandler: self.onError)```


- Once a request is made callbacks will be received through the eventHandler which the user can choose to react to or ignore.
  This can be a good place to update animation etc, to indicate to the user that recording is in progress.


```swift
func onVoysisEvent(event: Event) {
    switch event.type {
    case .recordingStarted:
        print("notifies that recording has started")
    case .recordingFinished:
        print("notifies that recording has finished")
    case .requestCancelled:
        print("notifies that request has been cancelled")
    case .audioQueryCreated:
        print("called when the initial connection json response is returned")
    case .audioQueryCompleted:
        print("called when final json response is returned.")
    }
}
```

- The `Voysis.Event` object contains two fields: `EventType` and `ApiResposne`.
 `EventType` is a status enum which will always be populated.
 `ApiResponse` is a protocol whos concrete implementation is a data class representation of the json response and will only be populated when the `EventType` is either `.audioQueryCreated`, or `.audioQueryCompleted`. 
 
When the EventType is `.audioQueryCreated` you can extract the *initial* response by doing the following.
   
```swift
if let response = event.response! as? QueryResponse {
    print("response is \(response)")
}
```
Note: This response indicates that a successful connection was made and returns meta-data. This resposne can be ignored by most users

When the EventType is `.audioQueryCompleted` you can extract the *final* response by doing the following
    
```swift
if let response = event.response! as? StreamResponse<CommerceContext, CommerceEntities> {
    if let data = try? encoder.encode(response),
        let json = String(data: data, encoding: .utf8) {
            print(json)
        }
    }
}
```

Integration - Carthage
-------------

Check out the [Carthage](https://github.com/Carthage/Carthage) docs on how to add and install.

To integrate the VoysisSdk into your Xcode project using Carthage, specify it in your Cartfile:

`github "/voysis/voysis-ios"`

- Once added, run `carthage update --no-use-binaries --platform iOS` from within your projects root directory.
- Next, from within xCode, in the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section. 
- Click `Add Other`
- Navigate to {{YOUR_PROJECT}}/Carthage/Build/iOS and click the `Voysis.framework` and `Starscream.framework`

Manual Integration - Embedded Framework
-------------


Note: This project requires [Carthage](https://github.com/Carthage/Carthage) to download the [Starscream](https://github.com/daltoniam/Starscream) websocket dependency

Adding Voysis Sdk
- First clone the project. Next, open the new `Voysis` folder, and drag the `Voysis.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see the `Voysis.framework` nested inside a `Products` folder.
- Select the `Voysis.framework` for iOS.

Adding Starscream
- From within the Voysis directory run `carthage update --no-use-binaries --platform iOS` to download the Starscream.framework
- Again Click on the `+` button under the "Embedded Binaries" section.
- Click `Add Other`
- Navigate to Voysis/Carthage/Build/iOS and click the Starscream.framework

IMPORTANT NOTE
-------------


As of iOS10 you will need to include `NSMicrophoneUsageDescription` in the application Info.plist

