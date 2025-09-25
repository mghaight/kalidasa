# Package Design
- the package should ship two objects for each text: first, a character vector
  with lines of the raw text; and second, a data frame where each row is a
  lemma/token
- the data frame should have the following cols:
    1. word in the text
    2. lemma
    3. part of speech (verb, noun, adj, compound element)
    4. a column for each no./pers./gen. for the word
    5. locator info (verse, pada numbers)
