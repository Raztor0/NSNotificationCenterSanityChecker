# NSNotificationCenterSanityChecker
Lets you know when an NSObject has been dealloc'd without calling -removeObserver: or -removeObserver:name:object:

## Do not use this in any production application
This code relies on swizzling the -dealloc method on NSObject. Only use it during development.

## How to use
Add all the .m and .h files to your project

You will get an assert if an object gets dealloc'd without removing itself as an observer from NSNotificationCenter

## Test it out
Put this line anywhere in your code:
```objective-c
[[NSNotificationCenter defaultCenter] addObserver:[NSObject new] selector:@selector(description) name:@"SomeNotification" object:nil];
```
