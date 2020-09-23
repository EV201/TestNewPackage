
test_that("summarize function works", {
  expect_equal(fars_summarize_years(2013)$`2013`[1], 2230)
})

test_that("this will throw an error", {
  expect_error(fars_map_state(0, 2013))
})

test_that("did return test value", {
  expect_equal(fars_map_state(1, 2013), 0)
})
