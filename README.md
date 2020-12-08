# UIDocument

## Exposing Your App’s File to the Files App
Configuring your app so that its files appear in the Files app is pretty simple. 
The easiest way to configure the app is to add the following two keys inside the main <dict> in the Xcode project’s Info.plist file:

    <key>UIFileSharingEnabled</key>
    <true/>
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <true/>


