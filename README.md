# Email Account Management

> A set of endpoints to manage email subscriptions without passwords

## Goal

This project allows users to manage an *account* or *subscription* via an email address.

Leverages the [serverless][0] framework to use [AWS Lambda][1] for server less architecture and [AWS S3][2] for cheap persisted storage.

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

Test the endpoints with your email address

```

```

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
