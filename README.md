# NSNotificationCenterSanityChecker
Lets you know when an object has been dealloc'd without calling -removeObserver:

## How to use
Add all the .m and .h files to your project
You will get an assert if an object gets dealloc'd without removing itself as an observer from NSNotificationCenter
