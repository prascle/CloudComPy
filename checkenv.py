print("Checking environment, Python test: import cloudComPy")
try:
	import cloudComPy as cc 
except:
	print("The environment seems to be incorrect! You need to check your Python environment for cloudComPy before running this script!")
	exit(1)
print("Environment OK!")
