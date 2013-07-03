package chris.AOPPlugin.aspects;

import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.util.LinkedHashMap;

import org.aspectj.lang.Signature;

public aspect InvocationCount {
	public final static boolean enabled = false;
	public PrintStream out;

	public InvocationCount() throws IOException {
		if (enabled) {
			File tmpFile = new File(new File(
					System.getProperty("java.io.tmpdir")),
					"InvocationCount.log");
			out = new PrintStream(tmpFile);
			System.out.println("Log goes to " + tmpFile.getCanonicalPath());
		}
	}

	pointcut git() : execution(* org.eclipse.jgit..*(..));

	pointcut gerrit() : execution(* com.google.gerrit..*(..));

	pointcut jetty() : execution(* org.eclipse.jetty..*(..));

	pointcut io() : execution(* java.io..*(..));

	pointcut all() : execution(* *..*(..));

	pointcut whiteList() : 
	    (git() || gerrit() || jetty()) ;
		// (io()) ;

	pointcut blackList() : 
		cflow(adviceexecution())
		|| execution(* org.eclipse.jgit.lib.AnyObjectId.*(..))
		|| execution(* org.eclipse.jgit.lib.Config.StringReader.read())
		|| execution(* org.eclipse.jgit.lib.FileMode..equals(..))
		|| execution(* org.eclipse.jgit.lib.FileMode.fromBits(..))
		|| execution(* org.eclipse.jgit.lib.ObjectId.fromString(..))
		|| execution(* org.eclipse.jgit.treewalk.AbstractTreeIterator.lastPathChar(..))
		|| execution(* org.eclipse.jgit.treewalk.CanonicalTreeParser.eof())
		|| execution(* org.eclipse.jgit.util.NB.*(..))
		|| execution(* org.eclipse.jgit.util.RawParseUtils.parseHexInt32(..))
		|| cflowbelow(execution(* *..toString(..)))
		|| cflowbelow(execution(* org.eclipse.jgit.dircache.DirCache.readFrom(..)))
		|| cflowbelow(execution(* org.eclipse.jgit.dircache.DirCache.writeTo(..)))
		|| cflowbelow(execution(* org.eclipse.jgit.dircache.DirCacheBuilder.resort(..)))
		|| cflowbelow(execution(* org.eclipse.jgit.dircache.DirCacheTree.validate(..)))
		|| cflowbelow(execution(* org.eclipse.jgit.lib.RefComparator.compare* (..)))
		|| cflowbelow(execution(* org.eclipse.jgit.storage.file.PackIndex.read(..)))
		|| cflowbelow(execution(* org.eclipse.jgit.treewalk.AbstractTreeIterator.getEntryObjectId(..))) 
		|| cflowbelow(execution(* org.eclipse.jgit.treewalk.AbstractTreeIterator.pathCompare(..)))
		|| cflowbelow(execution(* org.eclipse.jgit.treewalk.TreeWalk.getPathString()))
		|| cflowbelow(execution(* org.eclipse.jgit.util.RefList.Builder.sort(..)))
		|| cflowbelow(execution(* org.eclipse.jgit.util.StringUtils.equalsIgnoreCase(..)))
		|| cflowbelow(execution(* org.eclipse.jgit.lib.Config.get*(..)))
		;

	pointcut processed() : if(enabled) && whiteList() && !blackList();

	static ObjectCounter<Signature> signatureCount = new ObjectCounter<Signature>();
	static boolean initialized = false;

	before() : processed() {
		if (!initialized) {
			Runtime.getRuntime().addShutdownHook(new Thread() {
				public void run() {
					printCounts();
				}
			});
			initialized = true;
		}
		signatureCount.inc(thisJoinPointStaticPart.getSignature());
	}

	after() : execution(* *.main(..)) {
		if (enabled)
			printCounts();
	}

	public void printCounts() {
		out.println("Invocation counts:");
		out.println("Method Invocations:");
		LinkedHashMap<Signature, Integer> sigCount = signatureCount
				.sortByCount();
		ObjectCounter<String> packageCounter = new ObjectCounter<String>();
		for (Signature s : sigCount.keySet()) {
			Integer cnt = sigCount.get(s);
			out.println(s.toLongString() + ": " + cnt);
			packageCounter
					.inc(s.getDeclaringType().getPackage().getName(), cnt);
		}
		out.println("Package Invocations:");
		LinkedHashMap<String, Integer> packagesByCount = packageCounter
				.sortByCount();
		for (String s : packagesByCount.keySet())
			out.println(s + ": " + packagesByCount.get(s));
	}
}
