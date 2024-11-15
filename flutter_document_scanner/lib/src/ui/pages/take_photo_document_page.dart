// Copyright (c) 2021, Christian Betancourt
// https://github.com/criistian14
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_document_scanner/src/bloc/app/app.dart';
import 'package:flutter_document_scanner/src/ui/widgets/button_take_photo.dart';
import 'package:flutter_document_scanner/src/utils/take_photo_document_style.dart';

/// Page to take a photo
class TakePhotoDocumentPage extends StatefulWidget {
  /// Create a page with style
  const TakePhotoDocumentPage({
    super.key,
    required this.takePhotoDocumentStyle,
    required this.initialCameraLensDirection,
    required this.resolutionCamera,
  });

  /// Style of the page
  final TakePhotoDocumentStyle takePhotoDocumentStyle;

  /// Camera library [CameraLensDirection]
  final CameraLensDirection initialCameraLensDirection;

  /// Camera library [ResolutionPreset]
  final ResolutionPreset resolutionCamera;

  @override
  State<TakePhotoDocumentPage> createState() => _TakePhotoDocumentPageState();
}

class _TakePhotoDocumentPageState extends State<TakePhotoDocumentPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppBloc>().add(
            AppCameraInitialized(
              cameraLensDirection: widget.initialCameraLensDirection,
              resolutionCamera: widget.resolutionCamera,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppBloc, AppState, AppStatus>(
      selector: (state) => state.statusCamera,
      builder: (context, state) {
        switch (state) {
          case AppStatus.initial:
            return Container();

          case AppStatus.loading:
            return widget.takePhotoDocumentStyle.onLoading;

          case AppStatus.success:
            return _CameraPreview(
              takePhotoDocumentStyle: widget.takePhotoDocumentStyle,
            );

          case AppStatus.failure:
            return Container();
        }
      },
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({
    required this.takePhotoDocumentStyle,
  });

  final TakePhotoDocumentStyle takePhotoDocumentStyle;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppBloc, AppState, CameraController?>(
      selector: (state) => state.cameraController,
      builder: (context, state) {
        if (state == null) {
          return const Center(
            child: Text(
              'No Camera',
            ),
          );
        }

        // Add orientation handling
        final orientation = MediaQuery.of(context).orientation;
        final size = MediaQuery.of(context).size;

        // Calculate camera preview constraints based on orientation
        final previewRatio = state.value.previewSize!.height / state.value.previewSize!.width;
        final screenRatio = size.height / size.width;

        // Calculate preview dimensions to maintain aspect ratio
        Widget previewWidget = CameraPreview(state);
        if (orientation == Orientation.portrait) {
          final previewWidth = size.width;
          final previewHeight = size.width * previewRatio;
          previewWidget = SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: CameraPreview(state),
          );
        } else {
          // In landscape, we need to adjust the preview to fit the height
          final previewHeight = size.height;
          final previewWidth = size.height / previewRatio;
          previewWidget = SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: CameraPreview(state),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Camera
            Positioned(
              top: orientation == Orientation.portrait
                  ? takePhotoDocumentStyle.top
                  : 0,
              bottom: orientation == Orientation.portrait
                  ? takePhotoDocumentStyle.bottom
                  : 0,
              left: orientation == Orientation.portrait
                  ? takePhotoDocumentStyle.left
                  : 0,
              right: orientation == Orientation.portrait
                  ? takePhotoDocumentStyle.right
                  : 0,
              child: Center(
                child: previewWidget,
              ),
            ),

            // Children (overlay elements)
            if (takePhotoDocumentStyle.children != null)
              ...takePhotoDocumentStyle.children!,

            // Button position based on orientation
            Positioned(
              bottom: orientation == Orientation.portrait ? 20 : null,
              right: orientation == Orientation.landscape ? 20 : null,
              left: orientation == Orientation.portrait ? 0 : null,
              top: orientation == Orientation.landscape ? 0 : null,
              child: ButtonTakePhoto(
                takePhotoDocumentStyle: takePhotoDocumentStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
