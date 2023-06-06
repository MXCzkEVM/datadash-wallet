import 'package:equatable/equatable.dart';
import 'package:datadashwallet/features/home/home.dart';

class HomeMainPageState extends HomeBasePageState with EquatableMixin {
  Map applist = {};

  @override
  List<Object?> get props => [
        applist,
      ];
}