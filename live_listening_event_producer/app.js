export const handler = async (event, context) => {
  const promise = new Promise((resolve, reject) => {
    setTimeout(() => { resolve({ resolve: 200 }) }, 2000)
  })
  return promise;
}
