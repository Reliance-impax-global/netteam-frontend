# Net Team
## Banuba Video SDK used
1. Get the Banuba SDK from https://www.banuba.com/video-editor-sdk
2. Mubert API for audios https://pitch.com/public/fd02c60f-00a4-4a74-8772-423d4a607b94

Just get the API key from Banuba Video SDK and paste it in Home.dart, VideoSet.dart, ChatList.dart, AboutMeScreen.dart.
```
static const String LICENSE_TOKEN = "...";
```
Request for demo API from Mubert you will get license and token keys.
```
single {
            MubertApiConfig(
                mubertLicence = "...",
                mubertToken = "..."
            )
        }
```
