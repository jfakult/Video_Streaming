#include <libcamera/libcamera.h>
#include <iostream>

int main() {
    libcamera::CameraManager camera_manager;
    camera_manager.start();

    std::shared_ptr<libcamera::Camera> camera = camera_manager.get("camera0");
    if (!camera) {
        std::cerr << "Camera not found" << std::endl;
        return -1;
    }

    camera->acquire();
    libcamera::CameraConfiguration config = camera->generateConfiguration({ libcamera::StreamRole::VideoRecording });

    config.at(0).pixelFormat = libcamera::formats::YUYV;
    config.at(0).size = libcamera::Size(640, 480);
    config.at(0).bufferCount = 4;
    camera->configure(&config);

    libcamera::FrameBufferAllocator allocator(camera);
    allocator.allocate(config.at(0).stream());

    for (const auto &buffer : allocator.buffers(config.at(0).stream())) {
        camera->queueRequest(buffer->request);
    }

    camera->start();

    // Capture loop
    while (true) {
        libcamera::Request *request;
        camera->waitForRequest(&request);
        if (request->status() == libcamera::Request::RequestComplete) {
            // Process frame here
        }
        camera->queueRequest(request);
    }

    camera->stop();
    camera->release();
    camera_manager.stop();
    return 0;
}
