## Plugin API

**If you want use API you must include gather.inc in your code!**
```
#include < gather >
```
**Gather Plugin have three natives:**

```
native bool:g_bStart();
```
*Check for prepare, that is time before start match.*
```
native bool:IsStarted();
```
*Check match start, yes or no.*
```
native bool:SecondHalf();
```
*Check Second Half Start, yes or no.*

### You can see how use natives in examples plugins.
