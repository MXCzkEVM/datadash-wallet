import 'package:datadashwallet/common/common.dart';
import 'package:flutter/material.dart';
import 'package:mxc_ui/mxc_ui.dart';

class HomeSlider extends StatefulWidget {
  const HomeSlider({Key? key}) : super(key: key);

  @override
  State<HomeSlider> createState() => _HomeSliderState();
}

class _HomeSliderState extends State<HomeSlider> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Column(
            children: const [
              Expanded(flex: 35, child: ImageSlider()),
              Expanded(flex: 1, child: SliderIndicator())
            ],
          ),
        ),
      ),
    );
  }
}

class ImageSlider extends StatefulWidget {
  const ImageSlider({Key? key}) : super(key: key);

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: PageView(
        children: List.generate(
            7,
            (index) =>
                getSliderImage(ImagesTheme.of(context).sliderPlaceHolder)),
        onPageChanged: (value) => {},
      ),
    );
  }
}

Widget getSliderImage(ImageProvider img) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 10.0),
    decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        image: DecorationImage(image: img, fit: BoxFit.fill)),
  );
}

class SliderIndicator extends StatelessWidget {
  const SliderIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            7,
            (index) => const SliderIndicatorItem(
              indicate: false,
            ),
          )),
    );
  }
}

class SliderIndicatorItem extends StatelessWidget {
  final bool indicate;
  const SliderIndicatorItem({Key? key, required this.indicate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      width: 25,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: (indicate)
              ? ColorsTheme.of(context).whiteInverted
              : ColorsTheme.of(context).grey4),
    );
  }
}
