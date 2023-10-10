  titleSize(width){
    if(width >= 410){
      return [20.0, 35.0];
    }else{
      double sz = 411.0 - width;
      // print(18 - sz/22.75);
      // print(35 - sz/9.1);
      return [20 - sz/22.75, 35 - sz/9.1];
    }
  }