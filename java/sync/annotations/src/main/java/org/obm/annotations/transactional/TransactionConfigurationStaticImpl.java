package org.obm.annotations.transactional;

import com.google.inject.Singleton;

@Singleton
public class TransactionConfigurationStaticImpl implements TransactionConfiguration{

	protected TransactionConfigurationStaticImpl() {
		
	}
	
	private static int TIMEOUT_DURATION_IN_SECOND = 3600;
	
	public int getTimeOutInSecond(){
		return TIMEOUT_DURATION_IN_SECOND;
	}
	
}
