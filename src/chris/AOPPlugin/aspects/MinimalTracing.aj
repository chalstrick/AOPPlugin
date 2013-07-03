package chris.AOPPlugin.aspects;

public aspect MinimalTracing {
	public final static boolean enabled = false;

	pointcut processed() : 
	  if(enabled) &&
      execution(* com.google.gerrit..*(..)) && 
      !cflow(adviceexecution());

	before() : processed() {
		System.out.println("Entering ["
				+ thisJoinPointStaticPart.getSignature() + "]");
	}

	after() : processed() {
		System.out.println("Exciting ["
				+ thisJoinPointStaticPart.getSignature() + "]");
	}
}
