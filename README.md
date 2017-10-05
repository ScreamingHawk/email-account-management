# Email Account Management

> A set of endpoints to manage email subscriptions without passwords

## Goal

This project allows users to manage an *account* or *subscription* via an email address.

Leverages the [serverless][0] framework to use [AWS Lambda][1] for server less architecture and [AWS S3][2] for cheap persisted storage.

This project enables management through HTML forms (without JavaScript requirements) and direct links in emails.
This limitation means only GET and POST calls are allowed which breaks RESTful API conventions.

## Configuration

### AWS SES

Unfortunately, you cannot set up [AWS SES][3] with serverless or AWS CloudFormation so this has to be done manually.

**Note**: You will require either a domain or two valid email addresses.

#### Domain Verification

I use [AWS Route53][6] but you can use any registrar.

1. Log in to the [AWS Console][4]
2. Navigate to the [AWS SES Console][5]
3. Click `Domains`
4. Click `Verify a New Domain`
5. Enter your domain name and select `Generate DKIM`, then click `Verify this Domain`
6. Copy the records shown into your DNS hosted zones
7. Refresh the page and your domain should be listed as `Verified`

#### Email Verification

1. Log in to the [AWS Console][4]
2. Navigate to the [AWS SES Console][5]
3. Click `Email Addresses`
4. Click `Verify a New Email Address`
5. Enter your email address, then click `Verify this Email Address`
6. Open the email you will receive and click the link provided
7. Repeat steps 4-6 with another email address

#### Test Verification Worked

1. Click on the check box next an email address
2. Click `Send a Test Email`
3. If using a domain: Enter a `From` email prefix. This can be anything, even if there is no associated address
4. Enter a `To` email address that you have access to
5. Enter a `Subject`
6. Click `Send Test Email`
7. Check your email

### Serverless Configuration

Create configuration files for your development and production environments.

```
cp config.sample.json config.dev.json
cp config.sample.json config.prod.json
```

Edit `config.dev.json` and `config.prod.json` with your settings for your development and production environments respectively.

- **serviceName**: The name of your service
- **serviceEndpoint**: The endpoint of your service. This should either be your domain location. If you don't have a domain, you'll have to deploy without this value and then serverless will provide the value for you to redeploy with.
- **awsProfile**: The profile you have configured your AWS credentials with
- **awsRegion**: The endpoint and bucket region
- **awsSesArn**: The ARN for your SES
- **awsSesRegion**: The region you configured your SES
- **bucketName**: The name of the bucket to store the emails
- **sourceEmail**: The source email for the emails sent
- **replyToEmail**: The reply to email for the emails sent
- **confirmEmailTemplate**: Template information for the confirmation email
- - **subject**: The subject line for the confirmation email
- - **bodyText**: The plain text content for the confirmation email
- - **bodyHtml**: The HTML rich content for the confirmation email
- **confirmSuccessRedirect**: The URL the user will be redirected to on successful confirmation
- **confirmFailRedirect**: The URL the user will be redirected to on failed confirmation
- **removeSuccessRedirect**: The URL the user will be redirected to on successful removal
- **removeFailRedirect**: The URL the user will be redirected to on failed removal
- **removeRequiresToken**: Whether or not email removal requires the use of a token to confirm authenticity

## Build and Deployment

Install dependencies

```
npm install
```

Build the coffeescript files

```
node_modules/.bin/coffee -c .
```

Deploy the API

```
serverless deploy
```

## Test

### Request confirmation of email address

Test the endpoints with your email address

```
serverless invoke -f addEmail -d '{\"email\": \"<your_email_here>\"}' -l
```

Check you received an email

### Confirm email address

Take the token from the previous command and insert it into the next to test confirming the email address

```
serverless invoke -f confirmEmail -d '{\"email\": \"<your_email_here>\", \"token\": \"<output_token_here>\"}' -l
```

*OR*

Test in your browser by following the link in your email

*OR*

Construct the URL using and insert it to your browser as `<your_domain>/accounts/<your_email_here>/confirm?token=<output_token_here>`

### Remove the email address

Take the token from the previous command and insert it into the next to test deleting the email address

```
serverless invoke -f removeEmail -d '{\"email\": \"<your_email_here>\", \"token\": \"<output_token_here>\"}' -l
```

*OR*

Test in your browser by following the link in your email

*OR*

Construct the URL using and insert it to your browser as `<your_domain>/accounts/<your_email_here>/remove?token=<output_token_here>`

## Using it

If you got this far down **congratulations**! You're now ready to use your list of subscribed users.

1. Confirmed email subscriptions are located in `<your_bucket>/confirmed` with each file being the confirmed email address
2. Pending email subscriptions are located in `<your_bucket>/pending` with each file being the confirmed email address
3. The contents of the file is the token for confirmation (when pending) or deletion (when confirmed)

Simply list the `<your_bucket>/confirmed` contents to get a list of all email addresses.

It's good practice (and a legal requirement in some countries like New Zealand) to include the unsubscribe link in the emails.
This can be generated in the form `<your_domain>/<service_path>/accounts/<user_email>/remove`.
If `removeRequiresToken` is enabled, you'll also need to include `?token=<removal_token>`, which can be found in the file for each confirmed email address.

## Credits

[Michael Standen](https://michael.standen.link)

This software is provided under the [MIT License](https://tldrlegal.com/license/mit-license) so it's free to use so long as you give me credit.

[0]: https://serverless.com/
[1]: https://aws.amazon.com/lambda/
[2]: https://aws.amazon.com/s3/
[3]: https://aws.amazon.com/ses/
[4]: console.aws.amazon.com/console/home
[5]: https://console.aws.amazon.com/ses/
[6]: https://aws.amazon.com/route53/
