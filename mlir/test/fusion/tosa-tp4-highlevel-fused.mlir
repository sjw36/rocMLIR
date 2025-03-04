// RUN: rocmlir-driver --host-pipeline highlevel %s | FileCheck %s

module {
  // CHECK-LABEL: @test_conv_tp
  func.func @test_conv_tp(%arg0: tensor<256x28x28x128xf32>, %arg1: tensor<64x128x3x3xf32>, %arg2: tensor<256x64x28x28xf32>) -> tensor<256x28x28x64xf32> attributes {kernel, arch = "amdgcn-amd-amdhsa:gfx906"} {
    %cst_t = arith.constant dense<[0, 3, 1, 2]> : tensor<4xi32>
    %cst = arith.constant dense<[0, 2, 3, 1]> : tensor<4xi32>
    %cst_0 = arith.constant dense<0.000000e+00> : tensor<1xf32>
    %a = "tosa.transpose"(%arg0, %cst_t) : (tensor<256x28x28x128xf32>, tensor<4xi32>) -> tensor<256x128x28x28xf32>
    %a2 = "tosa.transpose"(%a, %cst) : (tensor<256x128x28x28xf32>, tensor<4xi32>) -> tensor<256x28x28x128xf32>
    %b = "tosa.transpose"(%arg1, %cst) : (tensor<64x128x3x3xf32>, tensor<4xi32>) -> tensor<64x3x3x128xf32>
    // CHECK: rock.conv(%{{.*}}, %{{.*}}, %{{.*}}) features =  dot {arch = "amdgcn-amd-amdhsa:gfx906", dilations = [1 : index, 1 : index], filter_layout = ["g", "k", "c", "y", "x"], input_layout = ["ni", "hi", "wi", "gi", "ci"], output_layout = ["no", "ho", "wo", "go", "ko"], padding = [1 : index, 1 : index, 1 : index, 1 : index], strides = [1 : index, 1 : index]} : memref<1x64x128x3x3xf32>, memref<256x28x28x1x128xf32>, memref<256x28x28x1x64xf32>
    // CHECK-COUNT-1: linalg.generic
    // CHECK-NOT: linalg.generic
    %c0 = "tosa.conv2d"(%a2, %b, %cst_0) {dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<256x28x28x128xf32>, tensor<64x3x3x128xf32>, tensor<1xf32>) -> tensor<256x28x28x64xf32>

    %c1 = "tosa.transpose"(%c0, %cst_t) : (tensor<256x28x28x64xf32>, tensor<4xi32>) -> tensor<256x64x28x28xf32>
    %c2 = "tosa.transpose"(%c1, %cst) : (tensor<256x64x28x28xf32>, tensor<4xi32>) -> tensor<256x28x28x64xf32>
    %1 = "tosa.transpose"(%arg2, %cst) : (tensor<256x64x28x28xf32>, tensor<4xi32>) -> tensor<256x28x28x64xf32>
    %2 = "tosa.add"(%c2, %1) : (tensor<256x28x28x64xf32>, tensor<256x28x28x64xf32>) -> tensor<256x28x28x64xf32>

    return %2 : tensor<256x28x28x64xf32>
  }

  // CHECK-LABEL: @test_conv_tp_reshape1
  func.func @test_conv_tp_reshape1(%arg0: tensor<1x256x28x28x128xf32>, %arg1: tensor<1x64x128x3x3xf32>, %arg2: tensor<1x256x64x28x28xf32>) -> tensor<1x256x28x28x64xf32> attributes {kernel, arch = "amdgcn-amd-amdhsa:gfx906"} {
    %cst_t = arith.constant dense<[0, 1, 4, 2, 3]> : tensor<5xi32>
    %cst = arith.constant dense<[0, 1, 3, 4, 2]> : tensor<5xi32>
    %cst_0 = arith.constant dense<0.000000e+00> : tensor<1xf32>
    %a = "tosa.transpose"(%arg0, %cst_t) : (tensor<1x256x28x28x128xf32>, tensor<5xi32>) -> tensor<1x256x128x28x28xf32>
    %a2 = "tosa.transpose"(%a, %cst) : (tensor<1x256x128x28x28xf32>, tensor<5xi32>) -> tensor<1x256x28x28x128xf32>
    %b = "tosa.transpose"(%arg1, %cst) : (tensor<1x64x128x3x3xf32>, tensor<5xi32>) -> tensor<1x64x3x3x128xf32>

    // CHECK: rock.conv(%{{.*}}, %{{.*}}, %{{.*}}) features =  dot {arch = "amdgcn-amd-amdhsa:gfx906", dilations = [1 : index, 1 : index], filter_layout = ["g", "k", "c", "y", "x"], input_layout = ["ni", "hi", "wi", "gi", "ci"], output_layout = ["no", "ho", "wo", "go", "ko"], padding = [1 : index, 1 : index, 1 : index, 1 : index], strides = [1 : index, 1 : index]} : memref<1x64x128x3x3xf32>, memref<256x28x28x1x128xf32>, memref<256x28x28x1x64xf32>
    // CHECK-COUNT-1: linalg.generic
    // CHECK-NOT: linalg.generic
    %a2_rshp = "tosa.reshape"(%a2) {new_shape = array<i64: 256, 28, 28, 128>} : (tensor<1x256x28x28x128xf32>) -> tensor<256x28x28x128xf32>
    %b_rshp = "tosa.reshape"(%b) {new_shape = array<i64: 64, 3, 3, 128>} : (tensor<1x64x3x3x128xf32>) -> tensor<64x3x3x128xf32>
    %c0 = "tosa.conv2d"(%a2_rshp, %b_rshp, %cst_0) {dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<256x28x28x128xf32>, tensor<64x3x3x128xf32>, tensor<1xf32>) -> tensor<256x28x28x64xf32>
    %c0_rshp = "tosa.reshape"(%c0) {new_shape = array<i64: 1, 256, 28, 28, 64>} : (tensor<256x28x28x64xf32>) -> tensor<1x256x28x28x64xf32>

    %c1 = "tosa.transpose"(%c0_rshp, %cst_t) : (tensor<1x256x28x28x64xf32>, tensor<5xi32>) -> tensor<1x256x64x28x28xf32>
    %c2 = "tosa.transpose"(%c1, %cst) : (tensor<1x256x64x28x28xf32>, tensor<5xi32>) -> tensor<1x256x28x28x64xf32>
    %1 = "tosa.transpose"(%arg2, %cst) : (tensor<1x256x64x28x28xf32>, tensor<5xi32>) -> tensor<1x256x28x28x64xf32>
    %2 = "tosa.add"(%c2, %1) : (tensor<1x256x28x28x64xf32>, tensor<1x256x28x28x64xf32>) -> tensor<1x256x28x28x64xf32>

    return %2 : tensor<1x256x28x28x64xf32>
  }

  // CHECK-LABEL: @test_conv_tp_reshape2
  func.func @test_conv_tp_reshape2(%arg0: tensor<256x28x28x128x1xf32>, %arg1: tensor<64x128x3x3x1xf32>, %arg2: tensor<256x64x28x28x1xf32>) -> tensor<256x28x28x64x1xf32> attributes {kernel, arch = "amdgcn-amd-amdhsa:gfx906"} {
    %cst_t = arith.constant dense<[0, 3, 1, 2, 4]> : tensor<5xi32>
    %cst = arith.constant dense<[0, 2, 3, 1, 4]> : tensor<5xi32>
    %cst_0 = arith.constant dense<0.000000e+00> : tensor<1xf32>
    %a = "tosa.transpose"(%arg0, %cst_t) : (tensor<256x28x28x128x1xf32>, tensor<5xi32>) -> tensor<256x128x28x28x1xf32>
    %a2 = "tosa.transpose"(%a, %cst) : (tensor<256x128x28x28x1xf32>, tensor<5xi32>) -> tensor<256x28x28x128x1xf32>
    %b = "tosa.transpose"(%arg1, %cst) : (tensor<64x128x3x3x1xf32>, tensor<5xi32>) -> tensor<64x3x3x128x1xf32>

    // CHECK: rock.conv(%{{.*}}, %{{.*}}, %{{.*}}) features =  dot {arch = "amdgcn-amd-amdhsa:gfx906", dilations = [1 : index, 1 : index], filter_layout = ["g", "k", "c", "y", "x"], input_layout = ["ni", "hi", "wi", "gi", "ci"], output_layout = ["no", "ho", "wo", "go", "ko"], padding = [1 : index, 1 : index, 1 : index, 1 : index], strides = [1 : index, 1 : index]} : memref<1x64x128x3x3xf32>, memref<256x28x28x1x128xf32>, memref<256x28x28x1x64xf32>
    // CHECK-COUNT-1: linalg.generic
    // CHECK-NOT: linalg.generic
    %a2_rshp = "tosa.reshape"(%a2) {new_shape = array<i64: 256, 28, 28, 128>} : (tensor<256x28x28x128x1xf32>) -> tensor<256x28x28x128xf32>
    %b_rshp = "tosa.reshape"(%b) {new_shape = array<i64: 64, 3, 3, 128>} : (tensor<64x3x3x128x1xf32>) -> tensor<64x3x3x128xf32>
    %c0 = "tosa.conv2d"(%a2_rshp, %b_rshp, %cst_0) {dilation = array<i64: 1, 1>, pad = array<i64: 1, 1, 1, 1>, stride = array<i64: 1, 1>} : (tensor<256x28x28x128xf32>, tensor<64x3x3x128xf32>, tensor<1xf32>) -> tensor<256x28x28x64xf32>
    %c0_rshp = "tosa.reshape"(%c0) {new_shape = array<i64: 256, 28, 28, 64, 1>} : (tensor<256x28x28x64xf32>) -> tensor<256x28x28x64x1xf32>

    %c1 = "tosa.transpose"(%c0_rshp, %cst_t) : (tensor<256x28x28x64x1xf32>, tensor<5xi32>) -> tensor<256x64x28x28x1xf32>
    %c2 = "tosa.transpose"(%c1, %cst) : (tensor<256x64x28x28x1xf32>, tensor<5xi32>) -> tensor<256x28x28x64x1xf32>
    %1 = "tosa.transpose"(%arg2, %cst) : (tensor<256x64x28x28x1xf32>, tensor<5xi32>) -> tensor<256x28x28x64x1xf32>
    %2 = "tosa.add"(%c2, %1) : (tensor<256x28x28x64x1xf32>, tensor<256x28x28x64x1xf32>) -> tensor<256x28x28x64x1xf32>

    return %2 : tensor<256x28x28x64x1xf32>
  }
}
