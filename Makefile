default: hexabomb

hexabomb:
	dub build

unittest:
	dub test

unittest-cov:
	dub test -b unittest-cov

clean:
	rm -f -- *.lst
	rm -f -- hexabomb hexabomb-test-application
