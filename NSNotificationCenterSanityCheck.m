#import "TargetConditionals.h"
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_SIMULATOR
#import "JRSwizzle.h"

@interface NSNotificationCenterSanityCheck : NSObject

+ (void)addObserver:(void * _Nonnull * _Nonnull)observer forName:(NSString * _Nonnull)name;
+ (void)removeObserver:(void * _Nonnull * _Nonnull)observer forName:(NSString * _Nullable)name;

+ (void)objectHasBeenDeallocd:(void * _Nonnull * _Nonnull)object withOldClassName:(NSString *)oldClassName;

@end

@implementation NSNotificationCenter (SanityCheck)

- (void)sanityCheck_addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject {
    [self sanityCheck_addObserver:observer selector:aSelector name:aName object:anObject];
    
    if(observer) {
        void *obs = (__bridge void *)observer;
        [NSNotificationCenterSanityCheck addObserver:&obs forName:aName];
    }
}

- (id <NSObject>)sanityCheck_addObserverForName:(nullable NSNotificationName)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block {
    id <NSObject> result = [self sanityCheck_addObserverForName:name object:obj queue:queue usingBlock:block];
    
    void *obs = (__bridge void *)result;
    [NSNotificationCenterSanityCheck addObserver:&obs forName:name];
    return result;
}

- (void)sanityCheck_removeObserver:(id)observer {
    [self sanityCheck_removeObserver:observer];
    
    if(observer) {
        void *obs = (__bridge void *)observer;
        [NSNotificationCenterSanityCheck removeObserver:&obs forName:nil];
    }
}

- (void)sanityCheck_removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject {
    [self sanityCheck_removeObserver:observer name:aName object:anObject];
    
    if(observer) {
        void *obs = (__bridge void *)observer;
        [NSNotificationCenterSanityCheck removeObserver:&obs forName:aName];
    }
}

+ (void)load {
    NSError *error;
    [NSNotificationCenter jr_swizzleMethod:@selector(addObserver:selector:name:object:) withMethod:@selector(sanityCheck_addObserver:selector:name:object:) error:&error];
    
    if (error) {
        NSLog(@"An error ocurred while initializing %@: %@", NSStringFromClass(self), error);
        return;
    }
    
    error = nil;
    [NSNotificationCenter jr_swizzleMethod:@selector(addObserverForName:object:queue:usingBlock:) withMethod:@selector(sanityCheck_addObserverForName:object:queue:usingBlock:) error:&error];
    
    if (error) {
        NSLog(@"An error ocurred while initializing %@: %@", NSStringFromClass(self), error);
        NSLog(@"Attempting to reverse previous swizzle");
        [NSNotificationCenter jr_swizzleMethod:@selector(addObserver:selector:name:object:) withMethod:@selector(sanityCheck_addObserver:selector:name:object:) error:nil];
        return;
    }
    
    error = nil;
    [NSNotificationCenter jr_swizzleMethod:@selector(removeObserver:) withMethod:@selector(sanityCheck_removeObserver:) error:&error];
    
    if (error) {
        NSLog(@"An error ocurred while initializing %@: %@", NSStringFromClass(self), error);
        NSLog(@"Attempting to reverse previous swizzles");
        [NSNotificationCenter jr_swizzleMethod:@selector(addObserver:selector:name:object:) withMethod:@selector(sanityCheck_addObserver:selector:name:object:) error:nil];
        [NSNotificationCenter jr_swizzleMethod:@selector(addObserverForName:object:queue:usingBlock:) withMethod:@selector(sanityCheck_addObserverForName:object:queue:usingBlock:) error:nil];
        return;
    }
    
    error = nil;
    [NSNotificationCenter jr_swizzleMethod:@selector(removeObserver:name:object:) withMethod:@selector(sanityCheck_removeObserver:name:object:) error:&error];
    
    if (error) {
        NSLog(@"An error ocurred while initializing %@: %@", NSStringFromClass(self), error);
        NSLog(@"Attempting to reverse previous swizzles");
        [NSNotificationCenter jr_swizzleMethod:@selector(addObserver:selector:name:object:) withMethod:@selector(sanityCheck_addObserver:selector:name:object:) error:nil];
        [NSNotificationCenter jr_swizzleMethod:@selector(addObserverForName:object:queue:usingBlock:) withMethod:@selector(sanityCheck_addObserverForName:object:queue:usingBlock:) error:nil];
        [NSNotificationCenter jr_swizzleMethod:@selector(removeObserver:) withMethod:@selector(sanityCheck_removeObserver:) error:nil];
        return;
    }
}

@end

@implementation NSObject (SanityCheck)

- (void)nsobjDealloc {
    void *oldSelf = (__bridge void *)self;
    NSString *oldClassName = NSStringFromClass([self class]);
    [self nsobjDealloc];
    [NSNotificationCenterSanityCheck objectHasBeenDeallocd:&oldSelf withOldClassName:oldClassName];
}

+ (void)load {
    NSError *error;
    [NSObject jr_swizzleMethod:NSSelectorFromString(@"dealloc") withMethod:@selector(nsobjDealloc) error:&error];
    
    if(error) {
        NSLog(@"An error ocurred while initializing %@: %@", NSStringFromClass(self), error);
    }
}

@end

@implementation NSNotificationCenterSanityCheck

+ (NSMutableDictionary <NSString *, NSHashTable *> *)registeredObservers {
    static NSMutableDictionary <NSString *, NSHashTable *> *observerDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        observerDict = [NSMutableDictionary dictionary];
    });
    return observerDict;
}

/**
 Keep track of the keys in the dictionary ourselves rather than calling [NSDictionary allKeys]
 because that function call creates a new array which gets deallocated upon exiting +objectHasBeenDeallocd
 which creates an infinite loop
 */
+ (NSMutableSet <NSString *> *)keys {
    static NSMutableSet *mutableKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mutableKeys = [NSMutableSet set];
    });
    return mutableKeys;
}

+ (void)addObserver:(void * _Nonnull * _Nonnull)observer forName:(NSString * _Nonnull)name {
    NSAssert(name, @"+%s must be called with a non-nil name", __PRETTY_FUNCTION__);
    NSAssert(observer, @"+%s must be called with a non-nil pointer", __PRETTY_FUNCTION__);
    NSAssert(*observer, @"+%s must be called with a non-nil observer pointer", __PRETTY_FUNCTION__);
    
    @synchronized (self) {
        NSHashTable *hashTable;
        if (!(hashTable = [[self registeredObservers] objectForKey:name])) {
            hashTable = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaquePersonality];
            [[self registeredObservers] setObject:hashTable forKey:name];
        }
        
        [hashTable addObject:(__bridge id _Nullable)(*observer)];
        
        if (name) {
            [[self keys] addObject:name];
        }
    }
}

+ (void)removeObserver:(void * _Nonnull * _Nonnull)observer forName:(NSString * _Nullable)name {
    NSAssert(observer, @"+%s must be called with a non-nil pointer", __PRETTY_FUNCTION__);
    NSAssert(*observer, @"+%s must be called with a non-nil observer pointer", __PRETTY_FUNCTION__);
    
    @synchronized (self) {
        if (name) {
            NSHashTable *hashTable = [[self registeredObservers] objectForKey:name];
            if (hashTable) {
                [hashTable removeObject:(__bridge id _Nullable)(*observer)];
            }
            
            if ([hashTable count] == 0) {
                [[self keys] removeObject:name];
            }
        } else {
            for (NSString *key in [self keys]) {
                [[[self registeredObservers] objectForKey:key] removeObject:(__bridge id _Nullable)(*observer)];
            }
        }
    }
}

+ (void)objectHasBeenDeallocd:(void * _Nonnull * _Nonnull)object withOldClassName:(NSString *)oldClassname {
    NSAssert(object, @"+%s must be called with a non-nil pointer", __PRETTY_FUNCTION__);
    NSAssert(*object, @"+%s must be called with a non-nil object pointer", __PRETTY_FUNCTION__);
    
    @synchronized (self) {
        @autoreleasepool {
            for (NSString *key in [self keys]) {
                NSHashTable *hashTable = [[self registeredObservers] objectForKey:key];
                if ([hashTable containsObject:(__bridge id _Nullable)(*object)]) {
                    NSLog(@"%p [%@] was still observing notifications for: %@ when it was dealloc'd", *object, oldClassname, key);
                    [hashTable removeObject:(__bridge id _Nullable)(*object)];
                }
            }
        }
    }
}

@end

#endif
