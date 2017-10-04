AWS = require 'aws-sdk'
fs = require 'fs'
uuidv4 = require 'uuid/v4'

config = require "config.#{process.env.stage}.json"

s3 = new AWS.S3()
ses = new AWS.SES
	region: config.awsSesRegion

# Get the email data from S3
getS3 = (email, state, callback) =>
	params =
		Bucket: config.bucketName
		Key: "#{state}/#{email}"
	s3.getObject params, callback

# Put the email data in S3
putS3 = (email, state, data, callback) =>
	params =
		Bucket: config.bucketName
		Key: "#{state}/#{email}"
		Body: data
	s3.putObject params, callback

# Sends an email
sendEmail = (email, subject, textContent, htmlContent, callback) =>
	params =
		Destination:
			ToAddresses: [
				email
			]
		Message:
			Subject:
				Data: subject
			Body:
				Html:
					Data: htmlContent
				Text:
					Data: textContent
		Source: config.sourceEmail
		ReplyToAddresses: [
			config.replyToEmail ? config.sourceEmail
		]
	ses.sendEmail params, callback

# Respond with the given information
respondWith = (code, body, errMessage, callback) =>
	if errMessage? && !body?
		body =
			message: errMessage
	response =
		statusCode: code
		headers:
			'Access-Control-Allow-Origin': '*'
		body: JSON.stringify body
	callback errMessage, response


module.exports.addEmail = (event, context, lambdaCallback) =>
	if !event?.email?
		console.log event
		return respondWith 400, null, "Email not supplied", lambdaCallback
	email = event.email
	# Check completed only, if pending ignore and reset the request
	getS3 email, "completed", (err) ->
		if !err?
			# We want an error here
			return respondWith 409, null, "This email already exists", lambdaCallback
		if err.statusCode != 404
			# Error should be 404
			console.log err
			return respondWith 500, null, "Something unexpected went wrong when checking email", lambdaCallback
		# Good. Store it
		token = uuidv4()
		putS3 email, "pending", token, (err)->
			if err?
				console.log err
				return respondWith 500, null, "Something unexpected went wrong when adding email", lambdaCallback
			url = "#{config.serviceEndpoint}/accounts/#{email}/confirm?token=#{token}"
			bodyText = config.confirmEmailTemplate.bodyText.replace /{{confirmUrl}}/g, url
			bodyHtml = config.confirmEmailTemplate.bodyHtml.replace /{{confirmUrl}}/g, url
			sendEmail email, config.confirmEmailTemplate.subject, bodyText, bodyHtml, (err)->
				if err?
					console.log err
					return respondWith 500, null, "Something unexpected went wrong when sending email", lambdaCallback
				return respondWith 200, "Please check your email", null, lambdaCallback

module.exports.confirmEmail = (event, context, callback) =>
	response =
		statusCode: 200
		headers:
			'Access-Control-Allow-Origin': '*'
		body: JSON.stringify
			message: 'Go Serverless v1.0! Your function executed successfully!'
			input: event

	callback null, response

module.exports.deleteEmail = (event, context, callback) =>
	response =
		statusCode: 204
		headers:
			'Access-Control-Allow-Origin': '*'
		body: JSON.stringify
			message: 'Go Serverless v1.0! Your function executed successfully!'
			input: event

	callback null, response
