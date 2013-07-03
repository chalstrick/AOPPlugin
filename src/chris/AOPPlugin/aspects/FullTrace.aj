package chris.AOPPlugin.aspects;

import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.security.cert.X509Certificate;

import org.aspectj.lang.Signature;

public aspect FullTrace {
	public static boolean enabled = true;
	public static boolean justEntered = false;
	private int level = 0;
	public PrintStream out;
	
	public FullTrace() throws IOException {
		if (enabled) {
			File tmpFile = new File(new File(System.getProperty("java.io.tmpdir")), "FullTrace.log");
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

	before() : processed() {
		StringBuilder args = new StringBuilder();
		boolean first = true;
		for (Object arg : thisJoinPoint.getArgs()) {
			if (!first)
				args.append(',');
			first = false;
			args.append(describe(arg));
		}
		println();
		indent(level++);
		Signature sig = thisJoinPointStaticPart.getSignature();
		print(sig.getDeclaringType().getCanonicalName() + "." + sig.getName()
				+ "("
				// print(sig.getDeclaringType().getSimpleName() + "." +
				// sig.getName() + "("
				+ args + ") {");
		justEntered = true;
	}

	after() returning (Object o): processed() {
		prefixedAfter(o, "->");
	}

	after() throwing (Exception e): processed() {
		prefixedAfter(e, "!");
	}

	private final void indent(int level) {
		for (int i = 0; i < level; i++)
			print("  ");
	}

	private final static String describe(final Object o) {
		if (o == null)
			return "<null>";
		try {
			if (o instanceof X509Certificate)
				return ((X509Certificate) o).getIssuerDN().getName();
			return (o.toString().replace('\r', '.').replace('\n', '#'));
		} catch (Exception e) {
			return ("Excetion(" + e.toString() + ": "
					+ o.getClass().getSimpleName() + "@" + Integer
						.toHexString(o.hashCode()));
		}
	}

	private void println() {
		out.println();
	}

	private void print(String s) {
		out.print(s);
	}

	private void prefixedAfter(Object o, String prefix) {
		level--;
		if (!justEntered) {
			println();
			indent(level);
		}
		print("} " + prefix + " " + describe(o));
		justEntered = false;
	}
}
