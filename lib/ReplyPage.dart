import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe/swipe.dart';
import 'dart:convert';

import 'package:video_player/video_player.dart';

import 'ReplyPage.dart';
import 'Services/service.dart';
Map? videoResponse;
List? videoList;
List idList=[];
late int id;
class ReplyPage extends StatefulWidget{
  String url;
  ReplyPage({super.key, required this.url});

  @override
  State<ReplyPage> createState() => _ReplyPageState();
}

class _ReplyPageState extends State<ReplyPage> {
  late String URL;
  late String uri;
  late String Thumbnail;
  late String Title;
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;


  Future getProductsApi () async {
    URL=widget.url;
    http.Response response;
    response = await http.get(Uri.parse(URL));
    if(response.statusCode==200){
      setState(() {
        videoResponse = json.decode(response.body);
        videoList = videoResponse!["post"];
        for(int i=0;i<videoList!.length;i++){
          idList.add(videoList![i]["id"]);
        }
      });
    }
  }
  readInfo() async{
    SharedPreferences sp = await SharedPreferences.getInstance();
    setState(() {
       Thumbnail = sp.getString("thumbnail")??"";
       Title = sp.getString("title")??"";
    });
  }
  writeInfo() async{
    SharedPreferences sp = await SharedPreferences.getInstance();
    setState(() {
      Thumbnail = videoList![id]["thumbnail_url"];
      Title =  videoList![id]["title"];
      sp.setString("thumbnail", Thumbnail);
      sp.setString("title", Title);
    });

  }
  readId() async{
    SharedPreferences sp = await SharedPreferences.getInstance();
    setState(() {
      id = sp.getInt("id")??0;
    });
  }
  writeId(int i) async{
    SharedPreferences sp = await SharedPreferences.getInstance();
    setState(() {
    });
    sp.setInt("id", i);
  }
  void initState(){
    readId();
    getProductsApi();
    readInfo();
    super.initState();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    uri =videoList![id]["video_link"];
    _controller = VideoPlayerController.networkUrl(Uri.parse(uri));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
    return Scaffold(
      body:
      Swipe(
        onSwipeLeft: () {
          print(uri);
          writeId(0);
          _controller.pause();
          dispose();
          Navigator.push(context, MaterialPageRoute(builder: (context) => ReplyPage(url: "https://api.wemotions.app/posts/"+id.toString()+"/replies",)));
        },
        onSwipeUp: () {
          if(id+1!=idList.length){
            print(uri);
            writeId(id+1);
            _controller.pause();
            dispose();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ReplyPage(url: widget.url)));
          }
        },
        onSwipeDown: () {
          if(id-1!=-1){
            print(uri);
            writeId(id-1);
            _controller.pause();
            dispose();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ReplyPage(url: widget.url)));
          }
        },
        child: InkWell(onTap: () {
          print(uri);
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            // play
            _controller.play();
          }
        }, child: Container(
          alignment: Alignment.center,
          child: FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child:Stack(children: <Widget>[
                  VideoPlayer(_controller),
                  Positioned(
                    top:30,
                    left:30,
                    child: Container(
                      height: 70,
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Container(
                              width:50,
                              height: 70,
                              child: Image.network(Thumbnail)),
                          Container(
                              alignment: Alignment.center,
                              width: 300,
                              height: 70,
                              child: Text(Title,style:TextStyle(fontWeight: FontWeight.bold,color: Colors.white),textAlign: TextAlign.center,))
                        ],
                      ),),
                  ),],),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
        ),
      ),
    );
  }
}