import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mets_beats_app/Utilities/color_constant.dart';
import 'package:mets_beats_app/Utilities/size_utils.dart';
import 'package:mets_beats_app/presentation/about_us_app/about_us_screen.dart';
import 'package:mets_beats_app/presentation/rate_us_app/rate_us_app_screen.dart';
import 'package:mets_beats_app/presentation/song_request/song_request_form.dart';
import 'package:mets_beats_app/theme/app_style.dart';
import 'package:mets_beats_app/widgets/radio.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.Device_id,}) : super(key: key);
  final Device_id;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String audioUrl="";
  Timer? _timer;
  int _interval = 2;
  List respone = [];
  var resp = "";
  int flag = 0;
  bool isPlaying = false;
  double currentvol = 0.5;
  dynamic radioClass;
  bool isPlayCardVisible = false;
  dynamic currentlyPlaying;
  List stationList = [];
  List<String>? metadata;
  Map respo = {};
  List<dynamic> listAds = [];
  final audioPlayer = AudioPlayer();

  //////icecast radio api////////////////////////
  String streamUrl1 = "http://139.84.138.193:8000/mets/stream";

  ////////////////////api for normal radio////////////////////////////////
  String streamUrl2 = " https://cocoalabs.in/Mets_Radio_App/public/api/stream";
  // String streamUrl2 = "https://d947-61-3-117-7.ngrok-free.app/api/stream";

  // Future getPosts() async {
  //   print("Get Ads");
  //   final response = await http
  //       .get(Uri.parse('https://cocoalabs.in/Mets_Radio_App/public/api/ads'));
  //   print("Response${response.body}");
  //   var res = json.decode(response.body);
  //   respo = res;
  //   listAds = respo["ads"];
  //   if (response.statusCode == 200) {
  //     _buildAdsList(listAds);
  //   } else {
  //     throw Exception('Failed to load post');
  //   }
  //   return response;
  // }

  Future<void> audio_url() async {

    Map<String, dynamic> formData = {
      'device_id': "${widget.Device_id}",
    };
    print("Data ${formData}");
    Map<String, String> headers = {
      'Accept': 'application/json',
    };
    print("headers ${headers}");
    var response = await http.post(
      Uri.parse('https://cocoalabs.in/Mets_Radio_App/public/api/stream'),
      body: formData,
      headers: headers,
    );
    print("Response-->${response.body}");
    if (response.statusCode == 200) {
      final responseBody = response.body;
      print("Response Body--> $responseBody");
      final jsonResponse = jsonDecode(responseBody);
        setState(() {
          audioUrl = jsonResponse["song"]; // Adjust this based on your API response structure
        });
      // String  audioUrl = jsonResponse["song"];
      print("Audio-->${audioUrl}");
      await audioPlayer.play(UrlSource(audioUrl));
    } else {
      throw Exception('Failed to make the request');
    }

    // print("Get Flag");
    // final response = await http.get(
    //     Uri.parse('https://cocoalabs.in/RadioApp/public/api/get-radio-status'));
    // print("Response${response.body}");
    // var res = json.decode(response.body);
    // respo = res;
    // if (response.statusCode == 200) {
    //   setState(() {
    //     flag = res['status']; // Adjust this based on your API response structure
    //   });
    // } else {
    //   // If the server did not return a 200 OK response, throw an exception.
    //   throw Exception('Failed to load data');
    // }
    //
    // // Call fetchData again after a delay
    // await Future.delayed(Duration(seconds: 2)); // Adjust the delay as needed
  }

  Future getFlag() async {
    print("Get Status");
    final response = await http.get(
        Uri.parse('https://cocoalabs.in/Mets_Radio_App/public/api/get-radio-status'));
    print("Response${response.body}");
    var res = json.decode(response.body);
    respo = res;
    if (response.statusCode == 200) {
      flag = res['status'];
      if (flag == 0) {
        // Call the first API
         _playAudio(0);
      } else if (flag == 1) {
        // Call the second API
        _playAudio(1);
      }
    } else {
      throw Exception('Failed to load post');
    }
    return response;
  }

  Widget ErrorDesign() {
    return Padding(
      padding:
          const EdgeInsets.only(top: 30.0, bottom: 30, left: 15, right: 15),
      child: Container(
        alignment: Alignment.center,
        child: Center(
          child: const Text(
            'Kindly Connect to Internet..Please wait',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    audio_url();
    radioClass = RadioClass();
    readJson();
    PerfectVolumeControl.hideUI =
        false; //set if system UI is hided or not on volume up/down
    Future.delayed(Duration.zero, () async {
      currentvol = await PerfectVolumeControl.getVolume();
      setState(() {});
    });
    PerfectVolumeControl.stream.listen((volume) {
      setState(() {
        currentvol = volume;
      });
    });
    _initAudioPlayer(flag); // getFlag();// _startTimer();
    _timer = Timer.periodic(Duration(seconds: _interval), (Timer timer) {
      getFlag();
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    audioPlayer.dispose();
    radioClass.stop();
  }

  void _playAudio(int flagvalue) async {
    print("flagvalue->${flagvalue}");
    try {
      if (flagvalue == 1) {
        await audioPlayer.play(UrlSource(streamUrl1));
      } else {
        // Use the audioUrl if available, otherwise, fetch a new one
        if (audioUrl.isNotEmpty) {
          await audioPlayer.play(UrlSource(audioUrl));
        } else {
          await audio_url(); // Fetch a new audio URL
          await audioPlayer.play(UrlSource(audioUrl));
        }
      }
      setState(() {
        isPlaying = true;
      });
    } catch (error) {
      // Handle error if the stream cannot be played
      print("Error playing audio: $error");
    }
  }
  void _initAudioPlayer(int flag) {
    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      print("start........");
      if (state == PlayerState.completed) {
        // Audio playback completed, call audio_url to get a new URL
        audio_url();
      } else if (state == PlayerState.playing) {
        setState(() {
          isPlaying = true;
        });
      } else if (state == PlayerState.paused) {
        // Handle any errors here
        print("Audio player error: ${audioPlayer.pause()}");
      } else {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }



  void _pauseAudio() async {
    await audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }


  Future<void> readJson() async {
    final String response =
        await rootBundle.loadString('assets/json/station.json');
    List<dynamic> data = json.decode(response);

    setState(() {
      stationList.addAll(data);
    });
  }

  Future<void> radioPlayer(item) async {
    currentlyPlaying = item;
    radioClass.stop();

    setState(() {
      radioClass.setChannel(item);
    });

    radioClass.radioPlayer.stateStream.listen((value) {
      setState(() {
        isPlaying = value;
      });
    });

    radioClass.radioPlayer.metadataStream.listen((value) {
      setState(() {
        metadata = value;
      });
    });

    setState(() {
      isPlayCardVisible = true;
      stationList.asMap().forEach((index, items) {
        if (items == item) {
          if (item['isPlay'] == true) {
            stationList[index]['isPlay'] = false;
            radioClass.pause();
          } else {
            stationList[index]['isPlay'] = true;
            Future.delayed(
              const Duration(seconds: 1),
              () => radioClass.play(),
            );
          }
        } else {
          stationList[index]['isPlay'] = false;
        }
      });
    });
  }

  Future<void> play() async {
    radioClass.play();
    checkStation();
  }

  Future<void> pause() async {
    radioClass.pause();
    checkStation();
  }

  void _pauseAll() {
    _pauseAudio(); // Pause the audio player
    _timer?.cancel(); // Cancel the periodic API calls
  }

  void checkStation() {
    stationList.asMap().forEach((index, items) {
      if (items == currentlyPlaying) {
        if (currentlyPlaying['isPlay'] == true) {
          stationList[index]['isPlay'] = false;
          radioClass.pause();
        } else {
          stationList[index]['isPlay'] = true;
          Future.delayed(
            const Duration(seconds: 1),
            () => radioClass.play(),
          );
        }
      } else {
        stationList[index]['isPlay'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // audio_url();
    print("Device_Id->${widget.Device_id}");
    print("Flag-->${flag}");
    GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
    return SafeArea(
      child: Scaffold(
        key: _scaffoldState,
        backgroundColor: ColorConstant.black900,
        body: SizedBox(
          height: size.height,
          width: double.maxFinite,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: size.height,
                    width: double.maxFinite,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            height: size.height,
                            width: double.maxFinite,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Image.asset(
                                  "assets/images/background.png",
                                  alignment: Alignment.center,
                                ),
                                Positioned(
                                  left: 10,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.menu,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _scaffoldState.currentState!.openDrawer();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 50),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Playing  Now",
                                        maxLines: null,
                                        textAlign: TextAlign.left,
                                        style: AppStyle.txtSFProDisplayBold30,
                                      ),
                                      Container(
                                        width: 200,
                                        margin: getMargin(
                                          top: 20,
                                        ),
                                        child: Text(
                                          "Enjoy the best top musics",
                                          maxLines: null,
                                          textAlign: TextAlign.center,
                                          style:
                                              AppStyle.txtSFProDisplayRegular16,
                                        ),
                                      ),
                                      SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.54,
                                      ),
                                      isPlaying
                                          ? ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                shape: const CircleBorder(),
                                                backgroundColor:
                                                    ColorConstant.pink500,
                                                elevation: 4.0,
                                                fixedSize: const Size(60, 60),
                                              ),
                                              onPressed: () {
                                                _pauseAll(); // Pause audio player and API calls
                                              },
                                              child: Icon(Icons.pause,
                                                  color:
                                                      ColorConstant.whiteA700,
                                                  size: 30),
                                            )
                                          : ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  shape: const CircleBorder(),
                                                  backgroundColor: ColorConstant
                                                      .pink500, //button's fill color
                                                  elevation: 4.0,
                                                  fixedSize:
                                                      const Size(60, 60)),
                                              onPressed: () {
                                                _playAudio(flag);
                                              },
                                              child: Icon(
                                                Icons.play_arrow,
                                                color: ColorConstant.whiteA700,
                                                size: 30,
                                              ),
                                            ),
                                      SizedBox(
                                        height: 10,
                                      ),


                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.volume_down,
                                            color: ColorConstant.whiteA700,
                                          ),
                                          SizedBox(
                                            width: 240,
                                            child: Slider(
                                              activeColor: Colors.pink,
                                              value: currentvol,
                                              onChanged: (newvol) {
                                                currentvol = newvol;
                                                PerfectVolumeControl.setVolume(
                                                    newvol); //set new volume
                                                setState(() {});
                                              },
                                              min: 0, //
                                              max: 3,
                                              divisions: 400,
                                            ),
                                          ),
                                          Icon(Icons.volume_up,
                                              color: ColorConstant.whiteA700),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 40,
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        drawer: _drawer(),
      ),
    );
  }

  Widget _buildAdsList(List adsList) {
    return CarouselSlider.builder(
        itemCount: adsList.length,
        options: CarouselOptions(
            autoPlay: true,
            aspectRatio: 2 / (5 / 3),
            enableInfiniteScroll: false,
            enlargeCenterPage: true,
            viewportFraction: 1),
        itemBuilder: (context, index, realIdx) {
          return CachedNetworkImage(
            fit: BoxFit.fill,
            imageUrl: adsList[index]["image"],
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: AssetImage('assets/images/dp.png'),
                // height: 60,
                // width: 60,
              ),
            ),
          );
        });
  }

  Widget _drawer() {
    String link =
        "https://play.google.com/store/apps/details?id=com.app.tuneinheartapp&hl=en-IN";
    print("Drawer show");
    return Container(
      width: 220,
      child: Drawer(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // backgroundColor: secondaryColor,
        // width: screenWidth,
        child: ListView(
          children: [
            SizedBox(
              height: 100,
              child: DrawerHeader(
                decoration: BoxDecoration(
                    color: Color(0xFF01011D),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12.0),
                    )
                    // gradient: LinearGradient(
                    //   colors: [ColorConstant.pink800,Colors.white,ColorConstant.pink800,],),
                    ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Image.asset(
                      "assets/images/logo-name-1.png",
                      height: 45,
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Image.asset(
                    //       "assets/images/app_logo.png",
                    //       height: 45,
                    //     ),
                    //     SizedBox(
                    //       width: 10,
                    //     ),
                    //     // Image.asset("assets/images/logo name-06.png",height:50,width: 130,),
                    //     Image.asset(
                    //       "assets/images/logo name-05.png",
                    //       height: 50,
                    //       width: 130,
                    //     ),
                    //     // Text("Tuneinheart",style:TextStyle(fontSize: 20,
                    //     //   fontWeight: FontWeight.bold,)),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
            // ListTile(
            //   onTap: (){
            //      Navigator.pop(context);
            //     // Navigator.push(context,
            //     //     MaterialPageRoute(builder: (context) => AboutUs()));
            //   },
            //   leading: Icon(Icons.favorite,color: Colors.black,),
            //   title: Text("My Favourites"),
            // ),
            ListTile(
              leading: Icon(
                Icons.music_note,
                color: Colors.black,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SongRequestFormScreen()));
              },
              title: Text("Request Song"),
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.info,
                color: Colors.black,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AboutUsScreen()));
              },
              title: Text("About Us"),
            ),
            ListTile(
              leading: Icon(
                Icons.star,
                color: Colors.black,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => RateUsScreen()));
              },
              title: Text("Rate Us"),
            ),

            ListTile(
              leading: Icon(
                Icons.share,
                color: Colors.black,
              ),
              onTap: () {
                Navigator.pop(context);
                Share.share('Hi, I am listening radio on Tuneinheart.'
                    'Download and enjoy the application from $link');
              },
              title: Text("Share"),
            ),
          ],
        ),
      ),
    );
  }
}
