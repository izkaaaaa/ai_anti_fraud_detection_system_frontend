
import 'package:flutter/material.dart';

class ToastUtils{
  // 阀门控制
  static bool showLoading = false;
  static void showToast(BuildContext context,String? msg){
    if (ToastUtils.showLoading) {
      return;
    }
    ToastUtils.showLoading = true;
    Future.delayed(Duration(seconds: 2),(){
      ToastUtils.showLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: 200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        behavior: SnackBarBehavior.floating,
        content: Text(msg??"数据刷新成功",textAlign: TextAlign.center,),
      )
    );
  }
}