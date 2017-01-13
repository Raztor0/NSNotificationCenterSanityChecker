# NSNotificationCenterSanityChecker
Lets you know when an NSObject has been dealloc'd without calling -removeObserver: or -removeObserver:name:object:

## Do not use this in any production application
This code relies on swizzling the -dealloc method on NSObject. Only use it during development.

The current functionality is completely wrapped inside of #if TARGET_IPHONE_SIMULATOR || TARGET_OS_SIMULATOR ... #endif

If you want to use the code on an actual device, remove the #if and #endif from the top and bottom of NSNotificationCenterSanityChecker.m

## How to use
Add all the .m and .h files to your project

You will get a log message if an object gets dealloc'd without removing itself as an observer from NSNotificationCenter. If you want to take a closer look at what was happening at the time of the dealloc, put a breakpoint on the NSLog line in the function +objectHasBeenDeallocd:withOldClassName:

## Test it out
Put this line anywhere in your code:
```objective-c
[[NSNotificationCenter defaultCenter] addObserver:[NSObject new] selector:@selector(description) name:@"SomeNotification" object:nil];
```
