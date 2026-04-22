#!/usr/bin/env python3
"""
PyTorch (.pth) to TensorFlow Lite (.tflite) Conversion Script

Model: SimpleCNN for Banana Leaf Disease Classification
Classes: 0 = Black Sigatoka, 1 = Fusarium Wilt, 2 = Healthy
"""

import argparse
import os
import tempfile
import shutil

def check_dependencies():
    """Check if required packages are installed."""
    try:
        import torch
        import torchvision
        import tensorflow as tf
        print(f"✓ PyTorch version: {torch.__version__}")
        print(f"✓ TensorFlow version: {tf.__version__}")
        return True
    except ImportError as e:
        print(f"✗ Missing dependency: {e}")
        print("\nPlease install required packages:")
        print("pip install torch torchvision tensorflow onnx onnx-tf")
        return False

# Define the SimpleCNN model architecture (your actual model)
import torch
import torch.nn as nn
import torch.nn.functional as F

class SimpleCNN(nn.Module):
    def __init__(self):
        super(SimpleCNN, self).__init__()
        self.conv1 = nn.Conv2d(3, 16, 3)
        self.conv2 = nn.Conv2d(16, 32, 3)
        self.fc1 = nn.Linear(32 * 30 * 30, 128)
        self.fc2 = nn.Linear(128, 3)  # 3 classes

    def forward(self, x):
        x = F.relu(self.conv1(x))
        x = F.max_pool2d(x, 2)
        x = F.relu(self.conv2(x))
        x = F.max_pool2d(x, 2)
        x = x.view(x.size(0), -1)
        x = F.relu(self.fc1(x))
        x = self.fc2(x)
        return x

def pytorch_to_onnx(model, output_path, input_shape=(1, 3, 128, 128)):
    """Convert PyTorch model to ONNX format."""
    model.eval()
    dummy_input = torch.randn(*input_shape)
    
    torch.onnx.export(
        model,
        dummy_input,
        output_path,
        export_params=True,
        opset_version=11,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={
            'input': {0: 'batch_size'},
            'output': {0: 'batch_size'}
        }
    )
    print(f"✓ ONNX model saved to: {output_path}")
    return output_path

def onnx_to_tensorflow(onnx_model_path, output_dir):
    """Convert ONNX model to TensorFlow SavedModel."""
    import onnx
    from onnx_tf.backend import prepare
    import tensorflow as tf
    
    onnx_model = onnx.load(onnx_model_path)
    tf_rep = prepare(onnx_model)
    tf_rep.export_graph(output_dir)
    print(f"✓ TensorFlow SavedModel saved to: {output_dir}")
    return output_dir

def tensorflow_to_tflite(saved_model_dir, output_path):
    """Convert TensorFlow SavedModel to TFLite."""
    import tensorflow as tf
    
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS,
    ]
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"✓ TensorFlow Lite model saved to: {output_path}")
    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"  Model size: {size_mb:.2f} MB")

def main():
    import sys
    
    if not check_dependencies():
        sys.exit(1)
    
    # Configuration
    MODEL_PATH = 'banana_model.pth'  # Your .pth file
    OUTPUT_PATH = 'leaf_disease_model.tflite'
    INPUT_SIZE = (1, 3, 128, 128)  # Your model's input size
    
    print(f"\nLoading PyTorch model from: {MODEL_PATH}")
    
    # Load model
    model = SimpleCNN()
    checkpoint = torch.load(MODEL_PATH, map_location='cpu')
    
    if 'model_state_dict' in checkpoint:
        model.load_state_dict(checkpoint['model_state_dict'])
    elif 'state_dict' in checkpoint:
        model.load_state_dict(checkpoint['state_dict'])
    else:
        model.load_state_dict(checkpoint)
    
    model.eval()
    print("✓ Model loaded successfully")
    
    # Create temp directory
    temp_dir = tempfile.mkdtemp()
    
    try:
        # Step 1: PyTorch -> ONNX
        print("\n[Step 1/3] Converting PyTorch to ONNX...")
        onnx_path = os.path.join(temp_dir, 'model.onnx')
        pytorch_to_onnx(model, onnx_path, INPUT_SIZE)
        
        # Step 2: ONNX -> TensorFlow
        print("\n[Step 2/3] Converting ONNX to TensorFlow...")
        tf_dir = os.path.join(temp_dir, 'saved_model')
        onnx_to_tensorflow(onnx_path, tf_dir)
        
        # Step 3: TensorFlow -> TFLite
        print("\n[Step 3/3] Converting TensorFlow to TFLite...")
        tensorflow_to_tflite(tf_dir, OUTPUT_PATH)
        
        print("\n" + "="*50)
        print("CONVERSION COMPLETE!")
        print("="*50)
        print(f"\nOutput file: {OUTPUT_PATH}")
        print("\nNext steps:")
        print(f"1. Copy {OUTPUT_PATH} to bananaapp/assets/")
        print("2. Run: flutter pub get")
        print("3. Run: flutter build apk --release")
        
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)

if __name__ == '__main__':
    main()
