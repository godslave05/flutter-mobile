import 'package:invoiceninja/data/models/models.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja/redux/invoice/invoice_actions.dart';
import 'package:invoiceninja/redux/app/app_state.dart';
import 'package:invoiceninja/data/repositories/invoice_repository.dart';

List<Middleware<AppState>> createStoreInvoicesMiddleware([
  InvoiceRepository repository = const InvoiceRepository(),
]) {
  final loadInvoices = _loadInvoices(repository);
  final saveInvoice = _saveInvoice(repository);
  final archiveInvoice = _archiveInvoice(repository);
  final deleteInvoice = _deleteInvoice(repository);
  final restoreInvoice = _restoreInvoice(repository);

  return [
    TypedMiddleware<AppState, LoadInvoicesAction>(loadInvoices),
    TypedMiddleware<AppState, SaveInvoiceRequest>(saveInvoice),
    TypedMiddleware<AppState, ArchiveInvoiceRequest>(archiveInvoice),
    TypedMiddleware<AppState, DeleteInvoiceRequest>(deleteInvoice),
    TypedMiddleware<AppState, RestoreInvoiceRequest>(restoreInvoice),
  ];
}

Middleware<AppState> _archiveInvoice(InvoiceRepository repository) {
  return (Store<AppState> store, action, NextDispatcher next) {
    var origInvoice = store.state.invoiceState().map[action.invoiceId];
    repository
        .saveData(store.state.selectedCompany(), store.state.authState,
        origInvoice, EntityAction.archive)
        .then((invoice) {
      store.dispatch(ArchiveInvoiceSuccess(invoice));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((error) {
      print(error);
      store.dispatch(ArchiveInvoiceFailure(origInvoice));
    });

    next(action);
  };
}

Middleware<AppState> _deleteInvoice(InvoiceRepository repository) {
  return (Store<AppState> store, action, NextDispatcher next) {
    var origInvoice = store.state.invoiceState().map[action.invoiceId];
    repository
        .saveData(store.state.selectedCompany(), store.state.authState,
        origInvoice, EntityAction.delete)
        .then((invoice) {
      store.dispatch(DeleteInvoiceSuccess(invoice));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((error) {
      print(error);
      store.dispatch(DeleteInvoiceFailure(origInvoice));
    });

    next(action);
  };
}

Middleware<AppState> _restoreInvoice(InvoiceRepository repository) {
  return (Store<AppState> store, action, NextDispatcher next) {
    var origInvoice = store.state.invoiceState().map[action.invoiceId];
    repository
        .saveData(store.state.selectedCompany(), store.state.authState,
        origInvoice, EntityAction.restore)
        .then((invoice) {
      store.dispatch(RestoreInvoiceSuccess(invoice));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((error) {
      print(error);
      store.dispatch(RestoreInvoiceFailure(origInvoice));
    });

    next(action);
  };
}

Middleware<AppState> _saveInvoice(InvoiceRepository repository) {
  return (Store<AppState> store, action, NextDispatcher next) {
    repository
        .saveData(store.state.selectedCompany(), store.state.authState,
            action.invoice)
        .then((invoice) {
      if (action.invoice.isNew()) {
        store.dispatch(AddInvoiceSuccess(invoice));
      } else {
        store.dispatch(SaveInvoiceSuccess(invoice));
      }
      action.completer.complete(null);
    }).catchError((error) {
      print(error);
      store.dispatch(SaveInvoiceFailure(error));
    });

    next(action);
  };
}

Middleware<AppState> _loadInvoices(InvoiceRepository repository) {
  return (Store<AppState> store, action, NextDispatcher next) {
    
    if (! store.state.invoiceState().isStale() && ! action.force) {
      next(action);
      return;
    }

    if (store.state.isLoading) {
      next(action);
      return;
    }

    store.dispatch(LoadInvoicesRequest());
    repository
        .loadList(store.state.selectedCompany(), store.state.authState)
        .then((data) {
      store.dispatch(LoadInvoicesSuccess(data));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((error) => store.dispatch(LoadInvoicesFailure(error)));

    next(action);
  };
}

