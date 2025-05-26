# Define a global platform for your project
platform :ios, '13.0' # Update to at least iOS 13 for compatibility

target 'exerun' do
  use_frameworks!

  # Add TensorFlow Lite for MediaPipe Pose Detection
  pod 'TensorFlowLiteSwift'
  
  pod 'GoogleSignIn', '~> 6.0'




  target 'exerunTests' do
    inherit! :search_paths
  end

  target 'exerunUITests' do
    inherit! :search_paths
  end

end
