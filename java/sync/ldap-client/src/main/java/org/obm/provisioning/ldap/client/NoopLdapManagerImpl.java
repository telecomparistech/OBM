/* ***** BEGIN LICENSE BLOCK *****
 * Copyright (C) 2011-2014  Linagora
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version, provided you comply with the Additional Terms applicable for OBM
 * software by Linagora pursuant to Section 7 of the GNU Affero General Public
 * License, subsections (b), (c), and (e), pursuant to which you must notably (i)
 * retain the displaying by the interactive user interfaces of the “OBM, Free
 * Communication by Linagora” Logo with the “You are using the Open Source and
 * free version of OBM developed and supported by Linagora. Contribute to OBM R&D
 * by subscribing to an Enterprise offer !” infobox, (ii) retain all hypertext
 * links between OBM and obm.org, between Linagora and linagora.com, as well as
 * between the expression “Enterprise offer” and pro.obm.org, and (iii) refrain
 * from infringing Linagora intellectual property rights over its trademarks and
 * commercial brands. Other Additional Terms apply, see
 * <http://www.linagora.com/licenses/> for more details.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License and
 * its applicable Additional Terms for OBM along with this program. If not, see
 * <http://www.gnu.org/licenses/> for the GNU Affero General   Public License
 * version 3 and <http://www.linagora.com/licenses/> for the Additional Terms
 * applicable to the OBM software.
 * ***** END LICENSE BLOCK ***** */
package org.obm.provisioning.ldap.client;

import org.obm.provisioning.Group;
import org.obm.provisioning.ldap.client.exception.ConnectionException;

import fr.aliacom.obm.common.domain.ObmDomain;
import fr.aliacom.obm.common.user.ObmUser;

public class NoopLdapManagerImpl implements LdapManager {

	private final static NoopLdapManagerImpl DEFAULT_INSTANCE = new NoopLdapManagerImpl();

	public static LdapManager of() {
		return DEFAULT_INSTANCE;
	}

	private NoopLdapManagerImpl() {
	}

	@Override
	public void createUser(ObmUser obmUser) {
	}

	@Override
	public void deleteUser(ObmUser obmUser) {
	}

	@Override
	public void modifyUser(ObmUser obmUser, ObmUser oldObmUser) {
	}

	@Override
	public void deleteGroup(ObmDomain domain, Group group) {
	}

	@Override
	public void addUserToGroup(ObmDomain domain, Group group, ObmUser userToAdd) {
	}

	@Override
	public void addUserToDefaultGroup(ObmDomain domain, Group defaultGroup, ObmUser userToAdd) {
	}

	@Override
	public void removeUserFromGroup(ObmDomain domain, Group group, ObmUser userToRemove) {
	}

	@Override
	public void removeUserFromDefaultGroup(ObmDomain domain, Group defaultGroup,
			ObmUser userToRemove) {
	}

	@Override
	public void addSubgroupToGroup(ObmDomain domain, Group group, Group subgroup) {
	}

	@Override
	public void removeSubgroupFromGroup(ObmDomain domain, Group group, Group subgroup) {
	}

	@Override
	public void modifyGroup(ObmDomain domain, Group group, Group oldGroup) {
	}

	@Override
	public void createGroup(Group group, ObmDomain domain) {
	}

	@Override
	public void shutdown() throws ConnectionException {
	}
}
