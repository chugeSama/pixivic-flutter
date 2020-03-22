import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:requests/requests.dart';
import 'package:random_color/random_color.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'pic_detail_page.dart';
import '../data/common.dart';

// 可以作为页面中单个组件或者单独页面使用的pic瀑布流组件,因可以作为页面，故不归为widget
class PicPage extends StatefulWidget {
  @override
  _PicPageState createState() => _PicPageState();

  PicPage({
    @required this.picDate,
    @required this.picMode,
    this.relatedId = 0,
    this.jsonMode = 'home',
    this.searchKeywords,
    this.searchManga,
    this.artistId,
    this.userId,
    this.needAuth = false,
  });

  PicPage.home({
    @required this.picDate,
    @required this.picMode,
    this.relatedId,
    this.jsonMode = 'home',
    this.searchKeywords,
    this.searchManga,
    this.artistId,
    this.userId,
    this.needAuth = false,
  });

  PicPage.related({
    @required this.relatedId,
    this.picDate,
    this.picMode,
    this.jsonMode = 'related',
    this.searchKeywords,
    this.searchManga,
    this.artistId,
    this.userId,
    this.needAuth = false,
  });

  PicPage.search({
    @required this.searchKeywords,
    this.picDate,
    this.picMode,
    this.jsonMode = 'search',
    this.relatedId,
    this.userId,
    this.searchManga = false,
    this.artistId,
    this.needAuth = false,
  });

  PicPage.artist({
    this.searchKeywords,
    this.picDate,
    this.picMode,
    this.jsonMode = 'artist',
    this.relatedId,
    this.userId,
    this.searchManga = false,
    @required this.artistId,
    this.needAuth = false,
  });

  PicPage.followed({
    this.searchKeywords,
    this.picDate,
    this.picMode,
    this.jsonMode = 'followed',
    this.relatedId,
    @required this.userId,
    this.searchManga = false,
    this.artistId,
    this.needAuth = true,
  });

  final String picDate;
  final String picMode;
  final num relatedId;
  final String artistId;
  final String userId;
  final String searchKeywords;
  final bool searchManga;
  final bool needAuth;
  // jsonMode could be set to 'home, related, Spotlight, tag, artist, search'
  final String jsonMode;
}

class _PicPageState extends State<PicPage> {
  // picList - 图片的JSON文件列表
  // picTotalNum - picList 中项目的总数（非图片总数，因为单个项目有可能有多个图片）
  List picList;
  int picTotalNum;
  RandomColor _randomColor = RandomColor();
  bool haveConnected = false;

  ScrollController scrollController;
  int currentPage;
  bool loadMoreAble = true;

  @override
  void initState() {
    print('PicPage Created');
    scrollController = ScrollController(initialScrollOffset: 0.0)
      ..addListener(_autoLoadMore);
    currentPage = 1;

    _getJsonList().then((value) {
      setState(() {
        picList = value;
        // 待修改，picList 为 null 则显示无的UI, didupdate 与 init 方法抽象出单独方法
        // 区分网络问题和结果为无的情况
        picTotalNum = value.length;
      });
    }).catchError((error) {
      print('======================');
      print(error);
      print('======================');
      if (error.toString().contains('NoSuchMethodError')) picList = null;
      haveConnected = true;
    });

    super.initState();
  }

  @override
  void didUpdateWidget(PicPage oldWidget) {
    currentPage = 1;
    // BotToast.showSimpleNotification(title: '图片重新装载中(ﾉ>ω<)ﾉ');
    try {
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    } catch (error) {
      scrollController = ScrollController(initialScrollOffset: 0.0)
        ..addListener(_autoLoadMore);
    }
    _getJsonList().then((value) {
      setState(() {
        picList = value;
        picTotalNum = value.length;
      });
    }).catchError((error) {
      print('======================');
      print(error);
      print('======================');
      if (error.toString().contains('NoSuchMethodError')) picList = null;
      haveConnected = true;
    });

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    print('PicPage Disposed');
    scrollController.removeListener(_autoLoadMore);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (picList == null) {
      return Center();
    } else if (picList == null && haveConnected) {
      return Center(
        child: Text('啊，你想访问的图片并不存在(´-ι_-｀)'),
      );
    } else {
      return Container(
          child: StaggeredGridView.countBuilder(
        controller: scrollController,
        crossAxisCount: 2,
        itemCount: picTotalNum,
        itemBuilder: (BuildContext context, int index) => imageCell(index),
        staggeredTileBuilder: (index) => StaggeredTile.fit(1),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      ));
    }
  }

  _getJsonList() async {
    // 获取所有的图片数据
    String url;
    List jsonList;
    if (widget.jsonMode == 'home') {
      url =
          'https://api.pixivic.com/ranks?page=$currentPage&date=${widget.picDate}&mode=${widget.picMode}&pageSize=30';
    } else if (widget.jsonMode == 'search') {
      if (!widget.searchManga)
        url =
            'https://api.pixivic.com/illustrations?illustType=illust&searchType=original&maxSanityLevel=6&page=$currentPage&keyword=${widget.searchKeywords}&pageSize=30';
      else
        url =
            'https://api.pixivic.com/illustrations?illustType=manga&searchType=original&maxSanityLevel=6&page=$currentPage&keyword=${widget.searchKeywords}&pageSize=30';
    } else if (widget.jsonMode == 'related') {
      url =
          'https://api.pixivic.com/illusts/${widget.relatedId}/related?page=$currentPage&pageSize=30';
    } else if (widget.jsonMode == 'artist') {
      if (!widget.searchManga) {
        url =
            'https://api.pixivic.com/artists/${widget.artistId}/illusts/illust?page=$currentPage&pageSize=30&maxSanityLevel=10';
      } else {
        url =
            'https://api.pixivic.com/artists/${widget.artistId}/illusts/manga?page=$currentPage&pageSize=30&maxSanityLevel=10';
      }
    } else if (widget.jsonMode == 'followed') {
      if (!widget.searchManga) {
        url =
            'https://api.pixivic.com/users/${widget.userId}/followed/latest/illust?page=1&pageSize=30';
      } else {
        url =
            'https://api.pixivic.com/users/${widget.userId}/followed/latest/manga?page=1&pageSize=30';
      }
    }

    try {
      if (!widget.needAuth) {
        var requests = await Requests.get(url);
        requests.raiseForStatus();
        jsonList = jsonDecode(requests.content())['data'];
        return (jsonList);
      }
      else {
        Map<String, String> headers = {
          'authorization': prefs.getString('auth')
        };
        var requests = await Requests.get(url, headers: headers);
        requests.raiseForStatus();
        jsonList = jsonDecode(requests.content())['data'];
        return (jsonList);
      }
    } catch (error) {
      print('======================');
      print(error);
      print('======================');
      if (error.toString().contains('SocketException'))
        BotToast.showSimpleNotification(title: '网络异常，请检查网络(´·_·`)');
    }
  }

  List _reviewPicUrlNumAspectRatio(int index) {
    // 预览图片的地址、数目、以及长宽比
    // String url = picList[index]['imageUrls'][0]['squareMedium'];
    String url = picList[index]['imageUrls'][0]['medium']; //medium large
    int number = picList[index]['pageCount'];
    double width = picList[index]['width'].toDouble();
    double height = picList[index]['height'].toDouble();
    return [url, number, width, height];
  }

  _autoLoadMore() {
    if ((scrollController.position.extentAfter < 350) &&
        (currentPage < 30) &&
        loadMoreAble) {
      currentPage++;
      loadMoreAble = false;
      print('current page is $currentPage');
      _getJsonList().then((value) {
        setState(() {
          picList = picList + value;
          picTotalNum = picTotalNum + value.length;
          print(picTotalNum);
          loadMoreAble = true;
          BotToast.showSimpleNotification(title: '摩多摩多!!!(つ´ω`)つ');
        });
      });
    }
  }

  Widget imageCell(int index) {
    final Color color = _randomColor.randomColor();
    Map picMapData = Map.from(picList[index]);
    return Stack(
      children: <Widget>[
        Positioned(
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(15),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PicDetailPage(picMapData)));
              },
              child: Container(
                // 限定constraints用于占用位置,经调试后以0.5为基准可以保证加载图片后不产生位移
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.width *
                      0.5 /
                      _reviewPicUrlNumAspectRatio(index)[2] *
                      _reviewPicUrlNumAspectRatio(index)[3],
                  minWidth: MediaQuery.of(context).size.width * 0.41,
                ),
                child: Hero(
                  tag: 'imageHero' + _reviewPicUrlNumAspectRatio(index)[0],
                  child: Image.network(
                    _reviewPicUrlNumAspectRatio(index)[0],
                    headers: {'Referer': 'https://app-api.pixiv.net'},
                    fit: BoxFit.fill,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) {
                        return child;
                      }
                      return Container(
                        child: AnimatedOpacity(
                          child:
                              frame == null ? Container(color: color) : child,
                          opacity: frame == null ? 0.3 : 1,
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeOut,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          child: numberViewer(_reviewPicUrlNumAspectRatio(index)[1]),
          right: ScreenUtil().setWidth(10),
          top: ScreenUtil().setWidth(5),
        )
      ],
    );
  }

  Widget numberViewer(num numberOfPic) {
    return (numberOfPic != 1)
        ? Container(
            padding: EdgeInsets.all(ScreenUtil().setWidth(2)),
            decoration: BoxDecoration(
                color: Colors.black38, borderRadius: BorderRadius.circular(3)),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.content_copy,
                  color: Colors.white,
                  size: ScreenUtil().setWidth(10),
                ),
                Text(
                  '$numberOfPic',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: ScreenUtil().setHeight(10),
                      decoration: TextDecoration.none),
                ),
              ],
            ),
          )
        : Container();
  }
}
