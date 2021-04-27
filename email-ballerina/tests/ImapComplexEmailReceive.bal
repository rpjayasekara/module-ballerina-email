// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/mime;
import ballerina/jballerina.java;
import ballerina/lang.'string as strings;
import ballerina/test;

@test:Config {
    dependsOn: [
        testReceiveSimpleEmailImap
    ]
}
function testReceiveComplexEmailImap() returns @tainted error? {

    string host = "127.0.0.1";
    string username = "hascode";
    string password = "abcdef123";

    Error? serverStatus = startComplexImapServer();
    if (serverStatus is Error) {
        test:assertFail(msg = "Error while starting complex IMAP server.");
    }

    Error? emailSendStatus = sendEmailComplexImapServer();
    if (emailSendStatus is Error) {
        test:assertFail(msg = "Error while sending email to complex IMAP server.");
    }

    ImapConfiguration imapConfig = {
         port: 3143,
         security: START_TLS_AUTO
    };
    string[] returnArray = [];
    ImapClient|Error imapClientOrError = new (host, username, password, imapConfig);
    if (imapClientOrError is Error) {
        test:assertFail(msg = "Error while initializing the IMAP4 client.");
    }
    ImapClient imapClient = check imapClientOrError;
    Message|Error? emailResponse = imapClient->receiveMessage();
    if (emailResponse is Message) {
        returnArray[0] = emailResponse.subject;
        string? emailBody = <string>emailResponse?.body;
        if (emailBody is string) {
            returnArray[1] = emailBody;
        }
        string? emailFrom= <string>emailResponse?.'from;
        if (emailFrom is string) {
            returnArray[2] = emailFrom;
        }
        returnArray[3] = getNonNilString(emailResponse?.sender);
        returnArray[4] = concatStrings(emailResponse.to);
        returnArray[5] = concatStrings(emailResponse?.cc);
        returnArray[6] = concatStrings(emailResponse?.replyTo);
        mime:Entity|Attachment|(mime:Entity|Attachment)[]? attachments = emailResponse?.attachments;
        if (attachments is (mime:Entity|Attachment)[]) {
            var att0 = attachments[0];
            if (att0 is mime:Entity) {
                string|error attachment1 = att0.getText();
                returnArray[7] = (attachment1 is string) ? attachment1 : "";
            }
            var att1 = attachments[1];
            if (att1 is mime:Entity) {
                var attachment2 = att1.getJson();
                if (attachment2 is json) {
                    returnArray[8] = !(attachment2 is ()) ? attachment2.toJsonString() : "";
                } else {
                    test:assertFail(msg = "JSON attachment is not in json type.");
                }
            }
            var att2 = attachments[2];
            if (att2 is mime:Entity) {
                string attachment3 = "";
                xml|error xml1 = att2.getXml();
                if (xml1 is xml) {
                    attachment3 = xml1.toString();
                }
                returnArray[9] = attachment3;
            }
            var att3 = attachments[3];
            if (att3 is mime:Entity) {
                var attachment4 = att3.getByteArray();
                if (attachment4 is byte[]) {
                    string|error byteString = strings:fromBytes(attachment4);
                    if (byteString is string) {
                        returnArray[10] = byteString;
                    } else {
                        test:assertFail(msg = "Error while converting byte array attachment to string.");
                    }
                } else {
                    test:assertFail(msg = "Byte Array attachment is not in byte[] type.");
                }
            }
            if (att0 is mime:Entity) {
                returnArray[11] = check att0.getHeader("H1");
                returnArray[12] = att0.getContentType();
            }
            json? headers = emailResponse?.headers;
            if (!(headers is ())) {
                json|error headerValue = headers.header1_name;
                if (headerValue is json && !(headerValue is ())) {
                    returnArray[13] = <string>headerValue;
                }
            }
        }

        test:assertEquals(returnArray[0], "Test E-Mail", msg = "Email subject is not matched.");
        test:assertEquals(returnArray[1], "This is a test e-mail.", msg = "Email body is not matched.");
        test:assertEquals(returnArray[2], "someone@localhost.com", msg = "Email from address is not matched.");
        test:assertEquals(returnArray[3], "someone2@localhost.com", msg = "Email sender is not matched.");
        test:assertEquals(returnArray[4], "hascode1@localhosthascode2@localhost",
            msg = "Email TO addresses are not matched.");
        test:assertEquals(returnArray[5], "hascode3@localhosthascode4@localhost",
            msg = "Email CC addresses are not matched.");
        test:assertEquals(returnArray[6], "reply1@abc.comreply2@abc.com",
            msg = "Email Reply TO addresses are not matched.");
        test:assertEquals(returnArray[7], "Sample attachment text", msg = "Email attachment text is not matched.");
        test:assertEquals(returnArray[8], "{\"bodyPart\":\"jsonPart\"}", msg = "Email attachment JSON is not matched.");
        test:assertEquals(returnArray[9], "<name>Ballerina xml file part</name>",
            msg = "Email attachment XML is not matched.");
        test:assertEquals(returnArray[10], "This is a sample source of bytes.",
            msg = "Email attachment binary is not matched.");
        test:assertEquals(returnArray[11], "V1", msg = "Email MIME header value is not matched.");
        test:assertTrue(strings:includes(returnArray[12], "text/plain"),
            msg = "Email content type is not matched.");
        test:assertEquals(returnArray[13], "header1_value", msg = "Email header value is not matched.");

    } else {
        test:assertFail(msg = "Error while reading emails in complex IMAP test.");
    }

    Error? closeStatus = imapClient->close();
    if (closeStatus is Error) {
        test:assertFail(msg = "Error while closing secure IMAP server.");
    }

    serverStatus = stopComplexImapServer();
    if (serverStatus is Error) {
        test:assertFail(msg = "Error while stopping complex IMAP server.");
    }

}

public function startComplexImapServer() returns Error? = @java:Method {
    'class: "org.ballerinalang.stdlib.email.testutils.ImapComplexEmailReceiveTest"
} external;

public function stopComplexImapServer() returns Error? = @java:Method {
    'class: "org.ballerinalang.stdlib.email.testutils.ImapComplexEmailReceiveTest"
} external;

public function sendEmailComplexImapServer() returns Error? = @java:Method {
    'class: "org.ballerinalang.stdlib.email.testutils.ImapComplexEmailReceiveTest"
} external;
