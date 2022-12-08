// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter image decode',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool networkDone = false;
  bool localDone = false;

  loadAndProcessImages() async {
    if (!networkDone) {
      networkDone = true;
      NetworkImage(imgUrl).resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((network, _) async {
          await processImageAndLoadResult(
            network.image,
            originalNetworkImage,
            pixelNetworkNoChange,
            pixelNetworkWithChange,
          );
        }),
      );
    }
    if (!localDone) {
      localDone = true;
      AssetImage(imgPathGreen).resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((local, _) async {
          await processImageAndLoadResult(
            local.image,
            originalLocalImage,
            pixelLocalNoChange,
            pixelLocalWithChange,
          );
        }),
      );
    }

    Future.delayed(Duration(seconds: 5)).then((_) => {setState(() {})});
  }

  processImageAndLoadResult(
    ui.Image image,
    ImageStatus original,
    ImageStatus pixelNoCahange,
    ImageStatus pixelWithChange,
  ) async {
    final ui.Image clonedImage = image.clone();
    original.image = clonedImage;

    final originalByteData = (await clonedImage.toByteData())!;
    printColors(originalByteData.buffer.asByteData());

    final pixalDataNoChanges = originalByteData.buffer.asByteData();
    ui.decodeImageFromPixels(
      pixalDataNoChanges.buffer.asUint8List(),
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      (ui.Image pixelResultNoChange) {
        pixelNoCahange.image = pixelResultNoChange;
      },
    );
    final pixelDataWithChanges = originalByteData.buffer.asByteData();
    for (int x = 0; x < 100; x++) {
      for (int y = 0; y < 100; y++) {
        final position = (y * clonedImage.width + x) * 4;
        pixelDataWithChanges.setUint32(position, 0xFF0000FF);
      }
    }

    ui.decodeImageFromPixels(
      pixelDataWithChanges.buffer.asUint8List(),
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      (ui.Image pixelResultWithChange) {
        pixelWithChange.image = pixelResultWithChange;
      },
    );
  }

  printColors(ByteData bytes) {
    // TODO ADD Comments
    for (var i = 0; i < 10; i += 4) {
      final red = 'R:${bytes.getUint8(i)}';
      final green = 'G:${bytes.getUint8(i + 1)}';
      final blue = 'B:${bytes.getUint8(i + 2)}';
      final alpha = 'A:${bytes.getUint8(i + 3)}';
      final message = ' $red $green $blue $alpha';
      print(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!networkDone || !localDone) {
      WidgetsBinding.instance!.addPostFrameCallback((_) async {
        await loadAndProcessImages();
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Channel beta, 3.6.0-0.1.pre'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [networkImages, localImages]
              .map((imagesForColumn) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: imagesForColumn
                      .map(
                        (imageStatus) => [
                          Text(imageStatus.description,),
                          if (imageStatus.image != null)
                            RawImage(
                              width: 200,
                              height: 200,
                              image: imageStatus.image!,
                            ),
                          if (imageStatus.status != null)
                            Text(imageStatus.status!,),
                        ],
                      )
                      .expand((w) => w)
                      .toList()))
              .toList(),
        ),
      ),
    );
  }
}

// const imgUrl = 'https://picsum.photos/250?image=9';
const imgUrl =
    'https://upload.wikimedia.org/wikipedia/commons/d/de/Color-Green.JPG';

const imgPath = 'assets/local.png';
const imgPathGreen = 'assets/localGreen.jpg';

class ImageStatus {
  ImageStatus(this.description);
  String description;
  ui.Image? image;
  String? status;
}

final originalNetworkImage = ImageStatus('original N');
final pixelNetworkNoChange = ImageStatus('pixel N');
final pixelNetworkWithChange = ImageStatus('pixel Red N');

final originalLocalImage = ImageStatus('original L');
final pixelLocalNoChange = ImageStatus('pixel L');
final pixelLocalWithChange = ImageStatus('pixels Red L');

List<ImageStatus> networkImages = [
  originalNetworkImage,
  pixelNetworkNoChange,
  pixelNetworkWithChange,
];
List<ImageStatus> localImages = [
  originalLocalImage,
  pixelLocalNoChange,
  pixelLocalWithChange,
];
