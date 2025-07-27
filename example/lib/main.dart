import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_watermark_plus/video_watermark_plus.dart';

void main() {
  runApp(const MyApp());
}

double width = 0;

double height = 0;

// ignore: constant_identifier_names
enum Pages { Watermark, Alignment, Padding, Opacity, Resize, Trim }

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      width = constraints.maxWidth;
      height = constraints.maxHeight;
      return MaterialApp(
        title: 'Video Watermark Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

List<WatermarkAlignment> alignmentList = [
  WatermarkAlignment.center,
  WatermarkAlignment.topCenter,
  WatermarkAlignment.bottomCenter,
  WatermarkAlignment.leftCenter,
  WatermarkAlignment.rightCenter,
  WatermarkAlignment.topLeft,
  WatermarkAlignment.topRight,
  WatermarkAlignment.bottomLeft,
  WatermarkAlignment.botomRight,
];

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController videoPlayerController;
  late TabController tabController;

  WatermarkAlignment? watermarkAlignment;

  int opacity = 100;

  late final List<TextEditingController> paddingControllers;

  late final TextEditingController widthController;

  late final TextEditingController heightController;

  late final TextEditingController opacityController;

  late Duration videoDuration;

  late Duration startTime;

  late Duration endTime;

  double? _progress;

  String? videoPath;

  WatermarkSource? imagePath;

  bool loading = false;

  bool lockAspectRatio = false;

  bool addWatermark = false;

  int currentPage = 0;

  @override
  void initState() {
    tabController = TabController(length: Pages.values.length, vsync: this);

    paddingControllers = List.generate(4, (index) => TextEditingController());

    opacityController = TextEditingController();

    widthController = TextEditingController();

    heightController = TextEditingController();

    startTime = const Duration();

    super.initState();
  }

  @override
  void dispose() {
    opacityController.dispose();
    videoPlayerController.dispose();
    widthController.dispose();
    heightController.dispose();
    tabController.dispose();
    for (var item in paddingControllers) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Video Watermark Demo"),
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                value: _progress,
              ),
            )
          : videoPath == null || imagePath == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ImagePicker()
                              .pickVideo(source: ImageSource.gallery)
                              .then((value) async {
                            setState(() {
                              loading = true;
                            });
                            if (value != null) {
                              videoPlayerController =
                                  VideoPlayerController.file(File(value.path));
                              await videoPlayerController
                                  .initialize()
                                  .then((video) {
                                setState(() {
                                  videoPath = value.path;
                                  videoDuration =
                                      videoPlayerController.value.duration;
                                  endTime = videoDuration;
                                  loading = false;
                                });
                              });
                            }
                          });
                        },
                        child: const Text("Select Video"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ImagePicker()
                              .pickImage(source: ImageSource.gallery)
                              .then((value) async {
                            if (value?.path != null) {
                              setState(() {
                                imagePath = WatermarkSource.file(value!.path);
                              });
                            }
                          });
                        },
                        child: const Text("Select Watermark"),
                      ),
                    ],
                  ),
                )
              : Builder(builder: (context) {
                  videoPlayerController.play();

                  videoPlayerController.setLooping(true);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        flex: 4,
                        child: AspectRatio(
                          aspectRatio: videoPlayerController.value.aspectRatio,
                          child: InkWell(
                            onTap: () {
                              videoPlayback();
                            },
                            child: VideoPlayer(videoPlayerController),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: height * 0.05,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (currentPage > 0) {
                                  currentPage--;
                                  changeOption();
                                }
                              },
                              icon: const Icon(Icons.arrow_back_ios),
                            ),
                            IconButton(
                              onPressed: () {
                                if (currentPage < Pages.values.length - 1) {
                                  currentPage++;
                                  changeOption();
                                }
                              },
                              icon: const Icon(Icons.arrow_forward_ios),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TabBarView(
                          controller: tabController,
                          children: List.generate(Pages.values.length, (index) {
                            return SizedBox(
                              width: width,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (index == 1 || index == 2)
                                    DropdownButton<WatermarkAlignment>(
                                      value: watermarkAlignment,
                                      hint: const Text("Select Alignment"),
                                      items: List.generate(
                                        alignmentList.length,
                                        (index) => DropdownMenuItem(
                                          child: Text(
                                            alignmentList[index].toString(),
                                          ),
                                          value: alignmentList[index],
                                        ),
                                      ),
                                      onChanged: (alignment) {
                                        setState(() {
                                          watermarkAlignment = alignment;
                                        });
                                      },
                                    ),
                                  if (index == 2)
                                    SizedBox(
                                      width: width,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          for (var i = 0;
                                              i < paddingControllers.length;
                                              i++)
                                            SizedBox(
                                              width: width * 0.2,
                                              child: TextField(
                                                controller:
                                                    paddingControllers[i],
                                                decoration: InputDecoration(
                                                  label: Text(i == 0
                                                      ? "Left"
                                                      : i == 1
                                                          ? "Right"
                                                          : i == 2
                                                              ? "Top"
                                                              : "Bottom"),
                                                  counterText: "",
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                maxLength: 3,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  if (index == 3)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: (() {
                                            if (opacity > 0) {
                                              setState(() {
                                                opacity -= 10;
                                              });
                                            }
                                          }),
                                          icon: const Icon(Icons.remove),
                                        ),
                                        SizedBox(
                                          width: width * 0.3,
                                          child: Text(
                                            "$opacity",
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: (() {
                                            if (opacity < 100) {
                                              setState(() {
                                                opacity += 10;
                                              });
                                            }
                                          }),
                                          icon: const Icon(Icons.add),
                                        ),
                                      ],
                                    ),
                                  if (index == 4)
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            SizedBox(
                                              width: width * 0.3,
                                              child: TextField(
                                                controller: widthController,
                                                decoration:
                                                    const InputDecoration(
                                                  label: Text("Width"),
                                                  counterText: "",
                                                ),
                                              ),
                                            ),
                                            if (!lockAspectRatio)
                                              SizedBox(
                                                width: width * 0.3,
                                                child: TextField(
                                                  controller: heightController,
                                                  decoration:
                                                      const InputDecoration(
                                                    label: Text("Height"),
                                                    counterText: "",
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        CheckboxListTile(
                                          value: lockAspectRatio,
                                          title:
                                              const Text("Lock aspect ratio"),
                                          onChanged: (value) {
                                            setState(() {
                                              lockAspectRatio = value ?? true;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  if (index == 5)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("Start"),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            IconButton(
                                              onPressed: (() {
                                                if (startTime >
                                                    const Duration()) {
                                                  setState(() {
                                                    startTime -= const Duration(
                                                        seconds: 1);
                                                  });
                                                }
                                              }),
                                              icon: const Icon(Icons.remove),
                                            ),
                                            SizedBox(
                                              width: width * 0.3,
                                              child: Text(
                                                startTime
                                                    .toString()
                                                    .split(".")
                                                    .first,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: (() {
                                                if (startTime < endTime) {
                                                  setState(() {
                                                    startTime += const Duration(
                                                        seconds: 1);
                                                  });
                                                }
                                              }),
                                              icon: const Icon(Icons.add),
                                            ),
                                          ],
                                        ),
                                        const Text("\nEnd"),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            IconButton(
                                              onPressed: (() {
                                                if (endTime > startTime) {
                                                  setState(() {
                                                    endTime -= const Duration(
                                                        seconds: 1);
                                                  });
                                                }
                                              }),
                                              icon: const Icon(Icons.remove),
                                            ),
                                            SizedBox(
                                              width: width * 0.3,
                                              child: Text(
                                                endTime
                                                    .toString()
                                                    .split(".")
                                                    .first,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: (() {
                                                if (endTime < videoDuration) {
                                                  setState(() {
                                                    endTime += const Duration(
                                                        seconds: 1);
                                                  });
                                                }
                                              }),
                                              icon: const Icon(Icons.add),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Checkbox(
                                                  value: addWatermark,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      addWatermark =
                                                          value ?? true;
                                                    });
                                                  },
                                                ),
                                                const Text("\t\tWatermark"),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (index == 2) {
                                        for (var element
                                            in paddingControllers) {
                                          if (element.text.isEmpty) {
                                            element.text = "0";
                                          }
                                        }

                                        if (watermarkAlignment != null) {
                                          watermarkAlignment!.padding =
                                              EdgeInsets.only(
                                            left: double.parse(
                                                paddingControllers[0].text),
                                            right: double.parse(
                                                paddingControllers[1].text),
                                            top: double.parse(
                                                paddingControllers[2].text),
                                            bottom: double.parse(
                                                paddingControllers[3].text),
                                          );
                                        }
                                      }

                                      VideoWatermark videoWatermark;

                                      switch (Pages.values[index]) {
                                        case Pages.Watermark:
                                          videoWatermark = VideoWatermark(
                                            sourceVideoPath: videoPath!,
                                            watermark: Watermark(
                                              image: imagePath!,
                                            ),
                                            progress: progress,
                                            onSave: onSave,
                                          );
                                          break;

                                        case Pages.Alignment:
                                          videoWatermark = VideoWatermark(
                                            sourceVideoPath: videoPath!,
                                            watermark: Watermark(
                                              image: imagePath!,
                                              watermarkAlignment:
                                                  watermarkAlignment,
                                            ),
                                            progress: progress,
                                            onSave: onSave,
                                          );
                                          break;

                                        case Pages.Padding:
                                          videoWatermark = VideoWatermark(
                                            sourceVideoPath: videoPath!,
                                            watermark: Watermark(
                                              image: imagePath!,
                                              watermarkAlignment:
                                                  watermarkAlignment,
                                            ),
                                            progress: progress,
                                            onSave: onSave,
                                          );
                                          break;

                                        case Pages.Opacity:
                                          videoWatermark = VideoWatermark(
                                            sourceVideoPath: videoPath!,
                                            watermark: Watermark(
                                              image: imagePath!,
                                              opacity: opacity / 100,
                                            ),
                                            progress: progress,
                                            onSave: onSave,
                                          );
                                          break;

                                        case Pages.Resize:
                                          videoWatermark = VideoWatermark(
                                            sourceVideoPath: videoPath!,
                                            watermark: Watermark(
                                              image: imagePath!,
                                              watermarkSize: lockAspectRatio
                                                  ? WatermarkSize.symmertric(
                                                      double.tryParse(
                                                              widthController
                                                                  .text) ??
                                                          0,
                                                    )
                                                  : WatermarkSize(
                                                      double.tryParse(
                                                              widthController
                                                                  .text) ??
                                                          0,
                                                      double.tryParse(
                                                              heightController
                                                                  .text) ??
                                                          0,
                                                    ),
                                            ),
                                            progress: progress,
                                            onSave: onSave,
                                          );
                                          break;

                                        case Pages.Trim:
                                          videoWatermark = VideoWatermark(
                                            sourceVideoPath: videoPath!,
                                            videoTrim: VideoTrim(
                                              start: startTime,
                                              end: endTime,
                                            ),
                                            watermark: addWatermark
                                                ? Watermark(
                                                    image: imagePath!,
                                                  )
                                                : null,
                                            onSave: onSave,
                                            progress: progress,
                                          );
                                          break;
                                      }

                                      generateVideo(videoWatermark);
                                    },
                                    child: Text(
                                      Pages.values[index].name,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                }),
    );
  }

  Future<void> generateVideo(VideoWatermark videoWatermark) async {
    videoPlayback();
    setState(() {
      loading = true;
    });

    await videoWatermark.generateVideo();
  }

  void progress(double percent) {
    setState(() {
      if (percent <= 1) {
        _progress = percent;
      } else {
        _progress = null;
      }
    });
  }

  void onSave(String? file) {
    if (file != null) {
      videoPlayerController = VideoPlayerController.file(File(file))
        ..initialize().then((value) {
          setState(() {
            loading = false;
          });
        });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  void changeOption() async {
    tabController.animateTo(
      currentPage,
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
  }

  Future<void> videoPlayback() async {
    if (videoPlayerController.value.isPlaying) {
      await videoPlayerController.pause();
    } else {
      await videoPlayerController.play();
    }
  }
}
