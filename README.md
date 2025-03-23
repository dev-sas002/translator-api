# Translator API

This is an API-only Ruby on Rails application that provides functionality to create, retrieve, and manipulate glossaries, terms and translations. The API response format is JSON.

## Prerequisites

- Ruby 3.1.3
- Rails 7.0.4
- Postgres DB
- Docker (for running app as container)

## Installation

Clone the github repository

```bash
git clone https://github.com/da-ehsan/glossary-translation-api.git
```

Install dependencies

```bash
bundle install
```

## Setup

### Docker

To run the application on Docker, just execute the following command. (Make sure docker is installed)

Note: Comment the marked code in `environment.rb` file before running these commands.

```bash
sudo docker compose up # run containers
sudo docker compose down # remove containers
```

### Database setup

In order to setup **Postgres** for local machine, add the required environment variables in
`/config/environment_variables.yml`.

For required variables see `database.yml` file.

```bash
rails db:create
rails db:migrate
```

### Start the server

```bash
rails server
```

### Execute tests

```bash
rspec # run all specs
rspec spec/models # run model specs
rspec spec/requests # run request specs
```

## Endpoints

### Glossary

```bash
# Endpoint
POST /glossaries
# Parameters
source_language_code: an ISO 639-1 language code
target_language_code: an ISO 639-1 language code

# curl
curl --location 'localhost:3000/glossaries' \
--header 'Content-Type: application/json' \
--data '{
    "glossary": {
    "source_language_code": "aa",
    "target_language_code": "af"
	}
}'

GET /glossaries #all glossaries with all their terms
curl --location 'localhost:3000/glossaries'

GET /glossaries/:id #glossary by id with all its terms
curl --location 'localhost:3000/glossaries'
```

### Term

```bash
# Endpoint
POST /glossaries/:id/terms

# Parameters
source_term: a source term
target_term: a target term

# curl
curl --location 'localhost:3000/glossaries/:glossary_id/terms' \
--header 'Content-Type: application/json' \
--data '{
    "term":{
        "source_term": "is",
        "target_term": "is"
    }
}'
```

### Translation

```bash
# Endpoint
POST /translations

# Parameters
source_language_code - an ISO 639-1 source language code
target_language_code - an ISO 639-1 target language code
source_text - a source text to be translated
glossary_id - an optional existing glossary id

# curl
curl --location 'localhost:3000/translations' \
--header 'Content-Type: application/json' \
--data '{
    "translation": {
        "source_language_code": "ab",
        "target_language_code": "af",
        "glossary_id": 2,
        "source_text": "This is a nato test"
    }
}'

GET /translations/:id # translation by id
curl --location 'localhost:3000/translations/'
```
