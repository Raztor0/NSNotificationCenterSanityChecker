# NSNotificationCenterSanityChecker
Lets you know when an object has been dealloc'd without calling -removeObserver:

## How to use
Add all the .m and .h files to your project
You will get an assert if an object gets dealloc'd without removing itself as an observer from NSNotificationCenter

## Test it out
Put this line anywhere in your code:
```objective-c
[[NSNotificationCenter defaultCenter] addObserver:[NSObject new] selector:@selector(description) name:@"SomeNotification" object:nil];
```
