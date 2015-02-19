/* ***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2011-2014  Linagora
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
package com.linagora.obm.ui.page;

import org.apache.commons.lang3.StringUtils;
import org.openqa.selenium.Alert;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import com.google.common.base.Predicate;
import com.google.common.collect.Iterables;
import com.linagora.obm.ui.bean.UIContact;

public class ContactPage extends RootPage {
	
	private WebElement addContact;
	protected WebElement informationGrid;
	protected WebElement dataGrid;
	private WebElement dataContainer;
	
	public ContactPage(WebDriver driver) {
		super(driver);
	}
	
	@Override
	public void open() {
		driver.get(mapping.lookup(ContactPage.class).toExternalForm());
	}

	public CreateContactPage openCreateContactPage() {
		addContact.click();
		
		new WebDriverWait(driver, 10).until(
				ExpectedConditions.presenceOfElementLocated(By.id("firstname")));
		
		return pageFactory.create(driver, CreateContactPage.class);
	}
	
	public int countContactsByFirstNameAndLastnameInList(UIContact contactToCheck) {
		String text = dataContainer.getText();
		return text.contains(contactToCheck.getFirstName() + " " + contactToCheck.getLastName()) ? 1 : 0;
	}

	public int countNameInAddressBookList(String name, String bookName) {
		selectAddressBook(bookName);

		return StringUtils.countMatches(dataContainer.getText(), name);
	}

	public void selectContact(final String contactDisplayName) {
		WebElement contactElement = Iterables.find(driver.findElements(By.className("contactHeader")), new Predicate<WebElement>() {

			@Override
			public boolean apply(WebElement input) {
				return StringUtils.contains(input.getText(), contactDisplayName);
			}

		});

		contactElement.click();
		waitForAjaxRequestToComplete();
	}

	public void selectAddressBook(String bookName) {
		driver.findElement(By.partialLinkText(bookName)).click();
		waitForAjaxRequestToComplete();
	}

	public void deleteContact() {
		findDeleteButton().click();
	}

	public WebElement findDeleteButton() {
		return Iterables.getFirst(driver.findElements(By.className("deleteButton")), null);
	}

	public void managePopup(final boolean accept) {
		new WebDriverWait(driver, 10).until(new Predicate<WebDriver>() {
			@Override
			public boolean apply(WebDriver input) {
				Alert alert = driver.switchTo().alert();
				if (alert != null) {
					if (accept) {
						alert.accept();
					} else {
						alert.dismiss();
					}
					return true;
				}
				return false;
			}
		});
	}

	private void waitForAjaxRequestToComplete() {
		new WebDriverWait(driver, 5).until(ExpectedConditions.invisibilityOfElementLocated(By.id("spinner")));
	}

}
