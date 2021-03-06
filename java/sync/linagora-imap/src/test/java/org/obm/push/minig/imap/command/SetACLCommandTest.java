package org.obm.push.minig.imap.command;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.Test;



public class SetACLCommandTest {
	
	@Test
	public void testSetACLCommand() {
		assertThat(new SetACLCommand("user/admin@vm.obm.org", "admin@vm.obm.org", "lrswidc")
			.getImapCommand()).isEqualTo("SETACL \"user/admin@vm.obm.org\" \"admin@vm.obm.org\" \"lrswidc\"");
	}
	
	@Test
	public void testSetACLCommandInUTF7() {
		assertThat(new SetACLCommand("user/adminé@vm.obm.org", "admin@vm.obm.org", "lrswidc")
			.getImapCommand()).isEqualTo("SETACL \"user/admin&AOk-@vm.obm.org\" \"admin@vm.obm.org\" \"lrswidc\"");
	}
}