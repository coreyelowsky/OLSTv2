// ImageJ Macro to update ImageJ memory and threads


// parse arguments
args = getArgument();
args = split(args, "?");

memory_gb = args[0];
threads = args[1];

print("");
print("################################");
print("Update ImageJ Memory and Threads");
print("################################");
print("");
print("Memory: " + memory_gb + " GB");
print("Threads: " + threads);
print("");

memory_mb=parseInt(memory_gb)*1000;

run("Memory & Threads...", "maximum="+memory_mb+" parallel="+threads);

print("");

eval("script","System.exit(0);");

run("Quit");
