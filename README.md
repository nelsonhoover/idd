# idd
Interactive dd Bash script

This is a Bash shell script intended to make the dd command on Linux a tiny bit easier to use.
- It accepts two arguments, the source and the destination for the dd copy operation.
- It displays a confirmation showing what it intends to copy and where, giving you the chance to cancel the copy before it starts, to help prevent mistakenly overwriting your main drive or something equally catastrophic.
- It runs a short test using a few different block sizes to see which is faster and automatically uses the fastest for the dd operation.
- It shows progress in the terminal during the copy, so you can see how it's coming along without having to resort to sending USR1 signals to the process from another terminal like dd does.
