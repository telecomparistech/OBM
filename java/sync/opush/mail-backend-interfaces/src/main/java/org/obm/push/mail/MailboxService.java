/* ***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2011-2012  Linagora
 *
 * This program is free software: you can redistribute it and/or 
 * modify it under the terms of the GNU Affero General Public License as 
 * published by the Free Software Foundation, either version 3 of the 
 * License, or (at your option) any later version, provided you comply 
 * with the Additional Terms applicable for OBM connector by Linagora 
 * pursuant to Section 7 of the GNU Affero General Public License, 
 * subsections (b), (c), and (e), pursuant to which you must notably (i) retain 
 * the “Message sent thanks to OBM, Free Communication by Linagora” 
 * signature notice appended to any and all outbound messages 
 * (notably e-mail and meeting requests), (ii) retain all hypertext links between 
 * OBM and obm.org, as well as between Linagora and linagora.com, and (iii) refrain 
 * from infringing Linagora intellectual property rights over its trademarks 
 * and commercial brands. Other Additional Terms apply, 
 * see <http://www.linagora.com/licenses/> for more details. 
 *
 * This program is distributed in the hope that it will be useful, 
 * but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License 
 * for more details. 
 *
 * You should have received a copy of the GNU Affero General Public License 
 * and its applicable Additional Terms for OBM along with this program. If not, 
 * see <http://www.gnu.org/licenses/> for the GNU Affero General Public License version 3 
 * and <http://www.linagora.com/licenses/> for the Additional Terms applicable to 
 * OBM connectors. 
 * 
 * ***** END LICENSE BLOCK ***** */
package org.obm.push.mail;

import java.io.IOException;
import java.io.InputStream;
import java.util.Collection;
import java.util.Date;
import java.util.Set;

import org.obm.push.bean.Address;
import org.obm.push.bean.UserDataRequest;
import org.obm.push.exception.DaoException;
import org.obm.push.exception.SendEmailException;
import org.obm.push.exception.SmtpInvalidRcptException;
import org.obm.push.exception.UnsupportedBackendFunctionException;
import org.obm.push.exception.activesync.ProcessingEmailException;
import org.obm.push.exception.activesync.StoreEmailException;
import org.obm.push.mail.bean.Email;
import org.obm.push.mail.bean.FastFetch;
import org.obm.push.mail.bean.Flag;
import org.obm.push.mail.bean.IMAPHeaders;
import org.obm.push.mail.bean.MailboxFolder;
import org.obm.push.mail.bean.MailboxFolders;
import org.obm.push.mail.bean.MessageSet;
import org.obm.push.mail.bean.UIDEnvelope;
import org.obm.push.mail.mime.IMimePart;
import org.obm.push.mail.mime.MimeAddress;
import org.obm.push.mail.mime.MimeMessage;

public interface MailboxService {
	
	MailboxFolders listSubscribedFolders(UserDataRequest udr) throws MailException;
	
	void updateReadFlag(UserDataRequest udr, String collectionPath, MessageSet messages, boolean read) throws MailException, ImapMessageNotFoundException;

	String parseMailBoxName(UserDataRequest udr, String collectionPath) throws MailException;

	void delete(UserDataRequest udr, String collectionPath, MessageSet messages) throws MailException, ImapMessageNotFoundException;

	long moveItem(UserDataRequest udr, String srcFolder, String dstFolder, long uid)
			throws MailException, DaoException, ImapMessageNotFoundException, UnsupportedBackendFunctionException;

	InputStream fetchMailStream(UserDataRequest udr, String collectionPath, long uid) throws MailException;

	void setAnsweredFlag(UserDataRequest udr, String collectionPath, long uid) throws MailException, ImapMessageNotFoundException;

	void sendEmail(UserDataRequest udr, Address from, Set<Address> setTo, Set<Address> setCc, Set<Address> setCci, InputStream mimeMail,
			boolean saveInSent) throws SendEmailException, ProcessingEmailException, SmtpInvalidRcptException, StoreEmailException;

	InputStream findAttachment(UserDataRequest udr, String collectionPath, Long mailUid, MimeAddress mimePartAddress) throws MailException;

	Collection<Long> purgeFolder(UserDataRequest udr, Integer devId, String collectionPath, Integer collectionId) throws MailException, DaoException;

	/**
	 * Store the mail's inputstream in INBOX.
	 * The mailContent is only guaranteed to be streamed if it's a SharedInputStream.
	 */
	void storeInInbox(UserDataRequest udr, InputStream mailContent, boolean isRead) throws MailException;

	boolean getLoginWithDomain();

	boolean getActivateTLS();
	
	Collection<Email> fetchEmails(UserDataRequest udr, String collectionPath, MessageSet messages) throws MailException;

	Set<Email> fetchEmails(UserDataRequest udr, String collectionPath, Date windows) throws MailException;

	MailboxFolders listAllFolders(UserDataRequest udr) throws MailException;
	
	void createFolder(UserDataRequest udr, MailboxFolder folder) throws MailException;
	
	Collection<FastFetch> fetchFast(UserDataRequest udr, String collectionPath, MessageSet messages) throws MailException;

	MimeMessage fetchBodyStructure(UserDataRequest udr, String collectionPath, long uid) throws MailException;
	
	Collection<MimeMessage> fetchBodyStructure(UserDataRequest udr, String collectionPath, Collection<Long> uids) throws MailException;

	Collection<Flag> fetchFlags(UserDataRequest udr, String collectionPath, long uid) throws MailException;

	InputStream fetchPartialMimePartStream(UserDataRequest udr, String collectionPath, long uid, MimeAddress partAddress, int limit) 
			throws MailException;

	InputStream fetchMimePartStream(UserDataRequest udr, String collectionPath, long uid, MimeAddress partAddress) 
			throws MailException;
	
	UIDEnvelope fetchEnvelope(UserDataRequest udr, String collectionPath, long uid) throws MailException;

	IMAPHeaders fetchPartHeaders(UserDataRequest udr, String collectionPath, long uid, IMimePart mimePart) throws IOException;

	void storeInSent(UserDataRequest udr, InputStream mailContent) throws MailException;

	long fetchUIDNext(UserDataRequest udr, String collectionPath) throws MailException;
	
	long fetchUIDValidity(UserDataRequest udr, String collectionPath) throws MailException;
}
