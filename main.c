#include <stdio.h>
#include <stdbool.h>

// Function declarations for our coroutine primitives implemented in assembly
// These form the core API of our coroutine system
void coroutine_init(void);                // Initialize the coroutine system
void coroutine_go(void (*f)(void));       // Create and start a new coroutine
void coroutine_yield(void);               // Yield execution to next coroutine

// Example coroutine function that counts from 0 to 9
// Each time it prints a number, it yields to allow other coroutines to run
void counter(void)
{
    for (int i = 0; i < 10; ++i) {
        printf("%d\n", i);        // Print current count
        coroutine_yield();        // Give up control to next coroutine
    }
}

int main()
{
    // Initialize the coroutine system
    // This sets up the first coroutine (main)
    coroutine_init();

    // Create two instances of the counter coroutine
    // They will run concurrently, taking turns executing
    coroutine_go(counter);        // First counter: will print 0,1,2,...,9
    coroutine_go(counter);        // Second counter: will print 0,1,2,...,9

    // Main loop - keep yielding forever
    // This allows the counter coroutines to alternate execution
    // The output will be interleaved: 0,0,1,1,2,2,...,9,9
    while (true) coroutine_yield();

    return 0;  // Never reached due to infinite loop above
}
