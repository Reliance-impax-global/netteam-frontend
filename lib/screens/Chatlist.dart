import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import '../main.dart';
import 'Chat.dart';
import 'UploadVideoForm.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  IO.Socket socket = IO.io(dotenv.env['BACKEND_URL'], <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });
  late String id;
  bool chatOpened = false;
  final List<UserList> _userList = <UserList>[];

  void handleChatClosed(bool isOpened) {
    // Handle the chat state here
    if (!isOpened) {
      chatOpened = false;
    }
  }

  Future<List<dynamic>> getChattedUsers() async {
    String apiUrl =
        "${dotenv.env['BACKEND_URL']}/usersAndUnseenChatsAndLastMessage";
    try {
      final response = await http.post(Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(<String, dynamic>{
            "userId": id,
          }));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        // Handle the error accordingly
      } else {
        // Other error occurred
        // Handle the error accordingly
      }
    } catch (error) {
      // Error occurred during the API call
      // Handle the error accordingly
    }
    return [];
  }

  /// part of video editor sdk
  static const String LICENSE_TOKEN =
      "Qk5CIKkm5ytxl2IprgpZeDVlf4sW6ZxFOPzhkKcC5vhe0aTOvwZtrBZckyubfOsQsd22kUWLCLHPDU16KcDp1H29ylxWdrWbKY/YOhCGqWvyFO9/F0g58XWpEfqTs2DMaQszms6KkBrRPNE5nW3TLdCNG+1ZUvZGNs3fjg28S+SR0lKPfnAUa1jbDZ8I5Qpa4UfNxDLxbmxrPCWiqwLRRP8Ujc0hzjBDfCTqXA/21kwLdtysYVYmx552hFwB5ME5IG5lcWPeSlZBknBISeg0r4QYQ4r2NtRsy8nQngzDrbLcW+TNwNDpUoGBD6uh7eiNTMzZwStxHd3VDv9bY3vCxQg6bIQ66ozq8yunKL0AUNVMEFuCXSavJUmsEEf1hez/yCc2d/8Zug7BmaATlNcnSHpypskNORFbb9lFbn+rNyckMN0vZxMpfm5oBoawPCdqsHyIlVLnvloSM+EadYCOun01fQI1ucecCbCvzsnUiY68G1gPrRHaXigQ+cpfsOWDEfFGBN+ZPH/B6GTA8CzjPE4TgDgnJrVaOnT+D1XHYcbGpzPqAUO45+TSxd3t4Lckw5nDgCfwh8JY4O7MA2lpnPpI+LDq2T0Ft782kdX4F2CnPe+ya4VGHiZzaLcNGoMVzNp/FupJM7JaJJ1OMvUpmg==";
  // static String? LICENSE_TOKEN = dotenv.env['BANUBA_LICENSE_TOKEN'];

  static const channelName = 'startActivity/VideoEditorChannel';

  static const methodInitVideoEditor = 'InitBanubaVideoEditor';
  static const methodStartVideoEditor = 'StartBanubaVideoEditor';
  static const methodStartVideoEditorPIP = 'StartBanubaVideoEditorPIP';
  static const methodStartVideoEditorTrimmer = 'StartBanubaVideoEditorTrimmer';
  static const methodDemoPlayExportedVideo = 'PlayExportedVideo';

  static const errMissingExportResult = 'ERR_MISSING_EXPORT_RESULT';
  static const errStartPIPMissingVideo = 'ERR_START_PIP_MISSING_VIDEO';
  static const errStartTrimmerMissingVideo = 'ERR_START_TRIMMER_MISSING_VIDEO';
  static const errExportPlayMissingVideo = 'ERR_EXPORT_PLAY_MISSING_VIDEO';

  static const errEditorNotInitializedCode = 'ERR_VIDEO_EDITOR_NOT_INITIALIZED';
  static const errEditorNotInitializedMessage =
      'Banuba Video Editor SDK is not initialized: license token is unknown or incorrect.\nPlease check your license token or contact Banuba';
  static const errEditorLicenseRevokedCode = 'ERR_VIDEO_EDITOR_LICENSE_REVOKED';
  static const errEditorLicenseRevokedMessage =
      'License is revoked or expired. Please contact Banuba https://www.banuba.com/faq/kb-tickets/new';

  static const argExportedVideoFile = 'exportedVideoFilePath';
  static const argExportedVideoCoverPreviewPath =
      'exportedVideoCoverPreviewPath';

  static const platform = MethodChannel(channelName);

  String _errorMessage = '';

  Future<void> _initVideoEditor() async {
    await platform.invokeMethod(methodInitVideoEditor, LICENSE_TOKEN);
  }

  Future<void> _startVideoEditorDefault() async {
    try {
      await _initVideoEditor();

      final result = await platform.invokeMethod(methodStartVideoEditor);

      _handleExportResult(result);
      print(result);
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
  }

  void _handleExportResult(dynamic result) {
    debugPrint('Export result = $result');

    // You can use any kind of export result passed from platform.
    // Map is used for this sample to demonstrate playing exported video file.
    if (result is Map) {
      final exportedVideoFilePath = result[argExportedVideoFile];

      // Use video cover preview to meet your requirements
      final exportedVideoCoverPreviewPath =
          result[argExportedVideoCoverPreviewPath];

      print("Edited video path $exportedVideoFilePath");

      /// pass this edited video to form screen
      Get.to(() => VideoUploadForm(
            videoFile: File(exportedVideoFilePath),
          ));

      // _showConfirmation(context, "Play exported video file?", () {
      //   platform.invokeMethod(
      //       methodDemoPlayExportedVideo, exportedVideoFilePath);
      // });
    }
  }

  // Handle exceptions thrown on Android, iOS platform while opening Video Editor SDK
  void _handlePlatformException(PlatformException exception) {
    debugPrint("Error: '${exception.message}'.");

    String errorMessage = '';
    switch (exception.code) {
      case errEditorLicenseRevokedCode:
        errorMessage = errEditorLicenseRevokedMessage;
        break;
      case errEditorNotInitializedCode:
        errorMessage = errEditorNotInitializedMessage;
        break;
      default:
        errorMessage = 'unknown error';
    }

    _errorMessage = errorMessage;
    setState(() {});
  }

  void _showConfirmation(
      BuildContext context, String message, VoidCallback block) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        actions: [
          MaterialButton(
            color: Colors.red,
            textColor: Colors.white,
            disabledColor: Colors.grey,
            disabledTextColor: Colors.black,
            padding: const EdgeInsets.all(12.0),
            splashColor: Colors.redAccent,
            onPressed: () => {Navigator.pop(context)},
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.0,
              ),
            ),
          ),
          MaterialButton(
            color: Colors.green,
            textColor: Colors.white,
            disabledColor: Colors.grey,
            disabledTextColor: Colors.black,
            padding: const EdgeInsets.all(12.0),
            splashColor: Colors.greenAccent,
            onPressed: () {
              Navigator.pop(context);
              block.call();
            },
            child: const Text(
              'Ok',
              style: TextStyle(
                fontSize: 14.0,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    socket.connect();
    id = Provider.of<MyDataContainer>(context, listen: false).id;
    getChattedUsers().then((users) => {
          setState(() {
            users.forEach((user) => _userList.add(UserList(
                imageUrl: user["profilePic"] != ""
                    ? '${dotenv.env["BACKEND_URL"]}/${user["profilePic"]}'
                    : "assets/images/avatar.jpg",
                userName: user["name"],
                recentText: user["lastMessage"],
                unseen: user["unseenCount"],
                onTap: (context) {
                  chatOpened = true;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Chat(
                                socket: socket,
                                handleChatClosed: handleChatClosed,
                                name: user["name"],
                                userID: user["_id"],
                              )));
                })));
          })
        });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    socket.dispose();
    super.dispose();
  }

  _getImageProvider(UserList user) {
    return Uri.parse(user.imageUrl).isAbsolute
        ? NetworkImage(user.imageUrl)
        : AssetImage(user.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0B1F),
        centerTitle: true,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        title: Text(
          'Messages',
          style: GoogleFonts.roboto(
              fontSize: 25.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ),
      backgroundColor: const Color(0xFF0E0B1F),
      body: ListView.builder(
        itemCount: _userList.length,
        itemBuilder: (context, index) {
          UserList user = _userList[index];
          return Card(
            margin: EdgeInsets.all(5.h),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListTile(
                  tileColor: const Color(0xFF272A35),
                  leading: CircleAvatar(
                    backgroundImage: _getImageProvider(user),
                  ),
                  title: Text(user.userName),
                  onTap: () {
                    user.onTap(context);
                  },
                  subtitle: Text(user.recentText),
                ),
                (user.unseen >
                        0) // Conditionally show the red circle when there are unseen messages
                    ? Positioned(
                        top: 10.0,
                        right: 10.0,
                        child: Container(
                          width: 10.0,
                          height: 10.0,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : SizedBox(), // If there are no unseen messages, use a SizedBox to occupy the space
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0.0,
        color: Color(0xFF0E0B1F),
        child: SizedBox(
          height: 60.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                child: SizedBox(
                    height: 40.h,
                    child: Icon(Icons.home,
                        size: 30.h, color: const Color(0xFFFFFFFF))),
                onTap: () {
                  //Navigate to Home
                  Navigator.pushReplacementNamed(context, "/");
                },
              ),
              GestureDetector(
                child: SizedBox(
                    height: 40.h,
                    child: Icon(Icons.videocam_rounded,
                        size: 30.h, color: const Color(0xFFFFFFFF))),
                onTap: () {
                  //Navigate to Video Call
                  Navigator.pushReplacementNamed(context, "/videoset");
                },
              ),
              GestureDetector(
                child: SizedBox(
                    height: 40.h,
                    child: Icon(Icons.add_circle_rounded,
                        size: 30.h, color: const Color(0xFFFFFFFF))),
                onTap: () {
                  //Navigate to Add tiktok
                  _startVideoEditorDefault();
                  // Navigator.pushReplacementNamed(context, "/create");
                },
              ),
              GestureDetector(
                child: SizedBox(
                    height: 40.h,
                    child: Icon(Icons.chat_bubble,
                        size: 30.h, color: const Color(0xFF1EA7D7))),
                onTap: () {
                  //Navigate to chat
                  Navigator.pushReplacementNamed(context, "/chatlist");
                },
              ),
              GestureDetector(
                child: SizedBox(
                    height: 40.h,
                    child: Icon(Icons.account_circle,
                        size: 30.h, color: const Color(0xFFFFFFFF))),
                onTap: () {
                  //Navigate to Account section
                  Navigator.pushReplacementNamed(context, "/aboutyou");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserList {
  String imageUrl;
  String userName;
  String recentText;
  int unseen;
  Function onTap;
  UserList(
      {required this.imageUrl,
      required this.userName,
      required this.recentText,
      required this.unseen,
      required this.onTap});
}
