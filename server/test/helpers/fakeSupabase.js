// Minimal fake for the chainable Supabase query builder, tailored to the
// exact call shapes used in this codebase (.from(table).select()...eq()
// .maybeSingle()/.single(), or a bare await with no terminal method).
// Responses are consumed FIFO per table in the order the code under test
// issues its calls -- call `setQueues` before each scenario to script them.

const createFakeSupabaseAdmin = () => {
  let queues = {};

  const setQueues = (nextQueues) => {
    queues = Object.fromEntries(
      Object.entries(nextQueues).map(([table, items]) => [table, [...items]])
    );
  };

  const makeBuilder = (table) => {
    const resolveNext = () => {
      const queue = queues[table];
      if (!queue || queue.length === 0) {
        throw new Error(`No fake Supabase response queued for table "${table}"`);
      }
      return queue.shift();
    };

    const builder = {
      select: () => builder,
      eq: () => builder,
      in: () => builder,
      neq: () => builder,
      order: () => builder,
      limit: () => builder,
      update: () => builder,
      upsert: () => builder,
      insert: () => builder,
      maybeSingle: () => Promise.resolve(resolveNext()),
      single: () => Promise.resolve(resolveNext()),
      then: (resolve, reject) => {
        try {
          resolve(resolveNext());
        } catch (error) {
          reject(error);
        }
      },
    };

    return builder;
  };

  return {
    admin: { from: (table) => makeBuilder(table) },
    setQueues,
  };
};

const mockSupabaseClientModule = (fakeAdmin) => {
  const supabaseClientPath = require.resolve('../../config/supabaseClient');
  const previousEntry = require.cache[supabaseClientPath];

  require.cache[supabaseClientPath] = {
    id: supabaseClientPath,
    filename: supabaseClientPath,
    loaded: true,
    exports: { supabaseAdmin: fakeAdmin },
    children: [],
    paths: [],
  };

  return () => {
    if (previousEntry) {
      require.cache[supabaseClientPath] = previousEntry;
    } else {
      delete require.cache[supabaseClientPath];
    }
  };
};

module.exports = { createFakeSupabaseAdmin, mockSupabaseClientModule };
